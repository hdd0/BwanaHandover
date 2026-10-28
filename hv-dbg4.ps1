<#
.SYNOPSIS
  Hyper-V Windows VM build/diagnose helpers. Wraps the commands that actually
  work on this host, and encodes the boot fixes learned on 2026-10-18.

.DESCRIPTION
  Every action returns a JSON object on stdout so callers (MCP server, CI,
  agents) can consume the result without parsing console text.

  Exit codes: 0 = OK, 1 = FAIL (and the JSON carries "status": "FAILED").

.NOTES
  Must be run with Windows PowerShell 5.1 (powershell.exe), not pwsh:
  the Hyper-V module fails to load under PS7 here.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'ListVms',
        'CreateWindowsVm',
        'SetSecureBoot',
        'SetBootOrder',
        'StartVm',
        'StopVm',
        'VmHealth',
        'VerifyIso',
        'ConsoleScreenshot',
        'ClearIsoMounts'
    )]
    [string]$Action,

    [string]$Name,
    [string]$IsoPath,
    [string]$Switch,
    [int]$VlanId = 150,
    [int]$VCpu = 2,
    [int]$MemoryGB = 2,
    [int]$DiskGB = 60,
    [string]$VhdRoot = 'C:\Hyper-V\AD',
    [ValidateSet('On', 'Off')]
    [string]$SecureBoot = 'Off',
    [string]$Template = 'MicrosoftWindows',
    [string]$CapturePath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$script:ExitCode = 0

function Emit {
    param([hashtable]$Data, [int]$Code = 0)
    $script:ExitCode = $Code
    $Data.ok = ($Code -eq 0)
    Write-Output ($Data | ConvertTo-Json -Depth 8 -Compress)
    # Do NOT call exit here: exiting from inside a function that runs within a
    # try block discards the buffered pipeline output on PowerShell 5.1.
}

function Fail {
    param([string]$Step, [string]$Message)
    Emit @{ status = 'FAILED'; action = $Step; error = $Message } 1
}

try {
    Write-Host ('DEBUG-ACTION=[' + $Action + '] type=' + $Action.GetType().Name)
    switch ($Action) {
        'ZZZNEVER' { Write-Host 'SHOULD-NOT-RUN' }

        'ListVms' {
            $vms = foreach ($vm in Get-VM) {
                $fw = $null; try { $fw = Get-VMFirmware -VMName $vm.Name } catch { }
                [PSCustomObject]@{
                    Name            = $vm.Name
                    State           = $vm.State
                    Generation      = $vm.Generation
                    SecureBoot      = if ($fw) { [string]$fw.SecureBoot } else { 'n/a' }
                    SecureBootTmpl  = if ($fw) { [string]$fw.SecureBootTemplate } else { 'n/a' }
                    VCPU            = $vm.ProcessorCount
                    MemoryStartupGB = [math]::Round((Get-VMMemory -VMName $vm.Name).Startup / 1GB, 2)
                    Checkpoints     = [string]$vm.CheckpointType
                    Switch          = (Get-VMNetworkAdapter -VMName $vm.Name -ErrorAction SilentlyContinue).SwitchName
                    VlanId          = (Get-VMNetworkAdapterVlan -VMName $vm.Name -ErrorAction SilentlyContinue).AccessVlanId
                }
            }
            Emit @{ status = 'OK'; action = 'ListVms'; count = @($vms).Count; vms = @($vms) } 0
        }

        'CreateWindowsVm' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            if (-not (Test-Path -LiteralPath $IsoPath)) { Fail $Action "ISO not found: $IsoPath" }
            if (-not (Get-VMSwitch -Name $Switch -ErrorAction SilentlyContinue)) { Fail $Action "Switch not found: $Switch" }

            $existing = Get-VM -Name $Name -ErrorAction SilentlyContinue
            if ($existing -and -not $Force) { Fail $Action "$Name already exists. Re-run with -Force to rebuild." }
            if ($existing) {
                if ($existing.State -ne 'Off') { Stop-VM -Name $Name -Force }
                Remove-VM -Name $Name -Force
            }

            $dir = Join-Path $VhdRoot $Name
            $vhd = Join-Path $dir "$Name.vhdx"
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            if (Test-Path -LiteralPath $vhd) { Remove-Item -LiteralPath $vhd -Force }

            # Do NOT pre-create the VHD with New-VHD; New-VM owns it when
            # -NewVHDPath and -NewVHDSizeBytes are both supplied (0x80070050 otherwise).
            $vm = New-VM -Name $Name -Generation 2 `
                    -MemoryStartupBytes ($MemoryGB * 1GB) `
                    -NewVHDPath $vhd -NewVHDSizeBytes ($DiskGB * 1GB) `
                    -SwitchName $Switch

            Set-VMProcessor -VMName $Name -Count $VCpu
            Set-VMMemory -VMName $Name -DynamicMemoryEnabled $false

            if ($VlanId -gt 0) {
                Get-VMNetworkAdapter -VMName $Name | ForEach-Object {
                    Set-VMNetworkAdapterVlan -VMName $Name -VMNetworkAdapterName $_.Name -Access -VlanId $VlanId
                }
            }

            Add-VMDvdDrive -VMName $Name -Path $IsoPath

            # Secure Boot default is OFF. On this Hyper-V build the Windows Server
            # 2025 ISO boot loader is rejected with "The boot loader failed."
            Set-VMFirmware -VMName $Name -EnableSecureBoot $SecureBoot -SecureBootTemplate $Template

            $dvd = Get-VMDvdDrive -VMName $Name | Select-Object -First 1
            $hdd = Get-VMHardDiskDrive -VMName $Name | Select-Object -First 1
            $net = Get-VMNetworkAdapter -VMName $Name
            Set-VMFirmware -VMName $Name -BootOrder $dvd, $hdd, $net

            Set-VM -Name $Name -AutomaticCheckpointsEnabled $false `
                         -CheckpointType Disabled `
                         -AutomaticStartAction Start `
                         -AutomaticStopAction Save
            try { Enable-VMIntegrationService -VMName $Name -Name 'Guest Service Interface' } catch { }

            $fw = Get-VMFirmware -VMName $Name
            Emit @{
                status = 'OK'; action = 'CreateWindowsVm'; name = $Name
                generation = 2; secureBoot = [string]$fw.SecureBoot
                secureBootTemplate = [string]$fw.SecureBootTemplate
                vcpu = $VCpu; memoryGB = $MemoryGB; diskGB = $DiskGB
                switch = $Switch; vlanId = $VlanId; iso = $IsoPath; vhd = $vhd
                bootOrder = @($fw.BootOrder | ForEach-Object { $_.Description })
            } 0
        }

        'SetSecureBoot' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            $vm = Get-VM -Name $Name -ErrorAction Stop
            if ($vm.State -ne 'Off') {
                Stop-VM -Name $Name -Force
                while ((Get-VM -Name $Name).State -ne 'Off') { Start-Sleep -Seconds 2 }
            }
            Set-VMFirmware -VMName $Name -EnableSecureBoot $SecureBoot -SecureBootTemplate $Template
            $fw = Get-VMFirmware -VMName $Name
            Emit @{ status = 'OK'; action = 'SetSecureBoot'; name = $Name; secureBoot = [string]$fw.SecureBoot; template = [string]$fw.SecureBootTemplate } 0
        }

        'SetBootOrder' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            $dvd = Get-VMDvdDrive -VMName $Name | Select-Object -First 1
            $hdd = Get-VMHardDiskDrive -VMName $Name | Select-Object -First 1
            $net = Get-VMNetworkAdapter -VMName $Name
            $items = @()
            if ($dvd) { $items += $dvd }
            if ($hdd) { $items += $hdd }
            if ($net) { $items += $net }
            Set-VMFirmware -VMName $Name -BootOrder $items
            $fw = Get-VMFirmware -VMName $Name
            Emit @{ status = 'OK'; action = 'SetBootOrder'; name = $Name; bootOrder = @($fw.BootOrder | ForEach-Object { $_.Description }) } 0
        }

        'StartVm' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            $before = (Get-Item (Join-Path $VhdRoot "$Name\$Name.vhdx") -ErrorAction SilentlyContinue).Length
            Start-VM -Name $Name
            Start-Sleep -Seconds 15
            $vm = Get-VM -Name $Name
            $after = (Get-Item (Join-Path $VhdRoot "$Name\$Name.vhdx") -ErrorAction SilentlyContinue).Length
            Emit @{ status = 'OK'; action = 'StartVm'; name = $Name; state = [string]$vm.State; vmStatus = [string]$vm.Status; uptime = [int]$vm.Uptime; diskBeforeMB = [math]::Round($before / 1MB, 1); diskAfterMB = [math]::Round($after / 1MB, 1) } 0
        }

        'StopVm' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            if ((Get-VM -Name $Name).State -ne 'Off') {
                Stop-VM -Name $Name -Force
                while ((Get-VM -Name $Name).State -ne 'Off') { Start-Sleep -Seconds 2 }
            }
            Emit @{ status = 'OK'; action = 'StopVm'; name = $Name; state = 'Off' } 0
        }

        'VmHealth' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            $vm = Get-VM -Name $Name -ErrorAction Stop
            $vhd = Join-Path $VhdRoot "$Name\$Name.vhdx"
            $size1 = (Get-Item $vhd -ErrorAction SilentlyContinue).Length
            Start-Sleep -Seconds 10
            $size2 = (Get-Item $vhd -ErrorAction SilentlyContinue).Length
            $hb = Get-VMIntegrationService -VMName $Name | Where-Object { $_.Name -eq 'Heartbeat' }
            Emit @{
                status = 'OK'; action = 'VmHealth'; name = $Name
                state = [string]$vm.State; vmStatus = [string]$vm.Status; uptime = [int]$vm.Uptime
                diskMB = [math]::Round($size2 / 1MB, 1)
                diskGrowing = ($size2 -gt $size1)
                heartbeat = if ($hb) { [string]$hb.PrimaryStatusDescription } else { 'unknown' }
                dvdPaths = @(Get-VMDvdDrive -VMName $Name | ForEach-Object { $_.Path })
            } 0
        }

        'VerifyIso' {
            if (-not (Test-Path -LiteralPath $IsoPath)) { Fail $Action "ISO not found: $IsoPath" }
            Mount-DiskImage -ImagePath $IsoPath -Access ReadOnly | Out-Null
            Start-Sleep -Seconds 4
            try {
                $vol = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5' |
                       Where-Object { $_.VolumeName -notmatch 'Audio CD' } | Select-Object -First 1
                if (-not $vol) { Fail $Action 'ISO mounted but no readable volume appeared.' }
                $root = $vol.DeviceID + '\'
                $probes = @('efi\boot\bootx64.efi', 'sources\boot.wim', 'setup.exe', 'sources\install.wim')
                $results = foreach ($p in $probes) {
                    $full = Join-Path $root $p
                    [PSCustomObject]@{ path = $p; present = (Test-Path -LiteralPath $full); bytes = if (Test-Path -LiteralPath $full) { (Get-Item -LiteralPath $full).Length } else { 0 } }
                }
                $uefiBootable = ($results | Where-Object { $_.path -eq 'efi\boot\bootx64.efi' }).present
                Emit @{
                    status = 'OK'; action = 'VerifyIso'; iso = $IsoPath
                    sizeGB = [math]::Round((Get-Item $IsoPath).Length / 1GB, 2)
                    label = $vol.VolumeName
                    uefiBootable = $uefiBootable
                    probes = @($results)
                } ($(if ($uefiBootable) { 0 } else { 1 }))
            }
            finally {
                Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
            }
        }

        'ClearIsoMounts' {
            $cleared = 0
            for ($i = 1; $i -le 12; $i++) {
                $vols = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5' | Where-Object { $_.VolumeName -notmatch 'Audio CD' })
                if ($vols.Count -eq 0) { break }
                Dismount-DiskImage -ImagePath $IsoPath -ErrorAction SilentlyContinue
                $cleared++
                Start-Sleep -Seconds 2
            }
            $remaining = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5' | Where-Object { $_.VolumeName -notmatch 'Audio CD' })
            Emit @{ status = 'OK'; action = 'ClearIsoMounts'; passes = $cleared; remaining = $remaining.Count } 0
        }

        'ConsoleScreenshot' {
            if (-not $Name) { Fail $Action 'Name is required.' }
            $proc = Get-Process vmconnect -ErrorAction SilentlyContinue |
                    Where-Object { $_.MainWindowTitle -like "*$Name*" } | Select-Object -First 1
            if (-not $proc) {
                Start-Process vmconnect.exe -ArgumentList $Name
                Start-Sleep -Seconds 10
                $proc = Get-Process vmconnect -ErrorAction SilentlyContinue |
                        Where-Object { $_.MainWindowTitle -like "*$Name*" } | Select-Object -First 1
            }
            if (-not $proc) { Fail $Action 'No VMConnect window found and launching one did not produce a window.' }
            $proc.Refresh()
            if (-not $CapturePath) { $CapturePath = Join-Path $env:TEMP "$Name-console.png" }

            Add-Type -AssemblyName System.Drawing
            Add-Type @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
public class WinCapMcp {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    public static Bitmap Capture(IntPtr hWnd) {
        RECT r;
        if (!GetWindowRect(hWnd, out r)) return null;
        int w = r.Right - r.Left, h = r.Bottom - r.Top;
        if (w <= 0 || h <= 0) return null;
        Bitmap bmp = new Bitmap(w, h);
        using (Graphics g = Graphics.FromImage(bmp)) {
            IntPtr hdc = g.GetHdc();
            PrintWindow(hWnd, hdc, 0x2);
            g.ReleaseHdc(hdc);
        }
        return bmp;
    }
}
'@ -ReferencedAssemblies System.Drawing

            $bmp = [WinCapMcp]::Capture($proc.MainWindowHandle)
            if ($null -eq $bmp) { Fail $Action 'PrintWindow produced no image.' }
            New-Item -ItemType Directory -Path (Split-Path -Parent $CapturePath) -Force | Out-Null
            $bmp.Save($CapturePath, [System.Drawing.Imaging.ImageFormat]::Png)
            $dim = "$($bmp.Width)x$($bmp.Height)"
            $bmp.Dispose()
            Emit @{ status = 'OK'; action = 'ConsoleScreenshot'; name = $Name; path = $CapturePath; dimensions = $dim; bytes = (Get-Item $CapturePath).Length; hint = 'Read this image to read any on-screen boot error.' } 0
        }
    }
}
catch {
    Fail $Action $_.Exception.Message
}

exit $script:ExitCode

