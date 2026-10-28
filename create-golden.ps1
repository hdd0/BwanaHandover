$ErrorActionPreference = 'Stop'
$name = 'BWANA-GOLDEN-SRC'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
$answer = 'C:\STEP\unattend\answer-GOLDEN.vhdx'
$switch = 'BWANA-AD-LAN'

foreach ($p in @($iso, $answer)) { if (-not (Test-Path $p)) { throw "missing: $p" } }
if (Get-VM -Name $name -ErrorAction SilentlyContinue) { throw "$name already exists" }

# Match the storage convention used by the existing lab VMs.
$ref = Get-VMHardDiskDrive -VMName BWANA-DC01 | Where-Object { $_.Path -notlike '*answer-*' } | Select-Object -First 1
$storeDir = Split-Path $ref.Path -Parent
Write-Output ("Reference VM disk dir: " + $storeDir)
$vhd = Join-Path $storeDir "$name.vhdx"
Write-Output ("Golden OS disk: " + $vhd)

$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
Write-Output ("Host free RAM = " + $freeGB + ' GB')
if ($freeGB -lt 9) { throw "Not enough RAM for an 8 GB build VM (free=$freeGB)" }

New-VHD -Path $vhd -SizeBytes 127GB -Dynamic | Out-Null
$vm = New-VM -Name $name -Generation 2 -MemoryStartupBytes 8GB `
    -Path $storeDir -VHDPath $vhd -SwitchName $switch
Write-Output ('CREATED ' + $name)

Set-VMProcessor -VMName $name -Count 4
Set-VM -Name $name -AutomaticStopAction ShutDown
Set-VM -Name $name -CheckpointType Standard

# This ISO fails to boot under the default UEFI-CA template (error 18604);
# the existing lab VMs use the MicrosoftWindows template.
Set-VMFirmware -VMName $name -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
Write-Output 'SET   SecureBoot template = MicrosoftWindows'

# VLAN 150 access, matching the rest of the AD lab.
$ad = Get-VMNetworkAdapter -VMName $name
Set-VMNetworkAdapterVlan -VMName $name -Access -VlanId 150
Write-Output 'SET   VLAN 150 access'

Add-VMDvdDrive -VMName $name -Path $iso -Passthru | Out-Null
Set-VMFirmware -VMName $name -FirstBootDevice (Get-VMDvdDrive -VMName $name)
Write-Output 'SET   DVD (ISO) attached and set as first boot device'

Add-VMHardDiskDrive -VMName $name -Path $answer
Write-Output 'SET   answer disk attached (unattended)'

Start-VM -Name $name
Write-Output ''
Write-Output 'SUMMARY'
Get-VM -Name $name | Select-Object Name, State, Generation, @{n = 'MemGB'; e = { [math]::Round($_.MemoryStartup / 1GB, 2) } }, ProcessorCount | Format-List
Get-VMFirmware -VMName $name | Select-Object SecureBoot, SecureBootTemplate, @{n = 'FirstBoot'; e = { $_.BootOrder[0].DeviceDescription } } | Format-List
Write-Output 'Setup is running unattended. It takes roughly 15-25 minutes.'