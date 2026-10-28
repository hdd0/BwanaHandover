$ErrorActionPreference = 'Continue'
$vmName = 'BWANA-GOLDEN-SRC'
Write-Output "=== DISK CONFIG ==="
Get-VMHardDisk -VMName $vmName | ForEach-Object {
    $vhd = Get-VHD -Path $_.Path
    Write-Output ("Controller {0} | {1} GB | {2} GB used | {3}" -f $_.ControllerNumber, [math]::Round($vhd.Size/1GB,1), [math]::Round($vhd.FileSize/1GB,1), (Split-Path $_.Path -Leaf))
    Write-Output ("   Path: {0}" -f $_.Path)
}
Write-Output ""
Write-Output "=== NETWORK ADAPTER DETAIL ==="
$gs = Get-VM -Name $vmName
Get-VMNetworkAdapter -VMName $vmName | ForEach-Object {
    Write-Output ("Switch: {0} | Status: {1}" -f $_.SwitchName, $_.Status)
}
Get-VMNetworkAdapter -VMName $vmName | Where-Object {$_.IPAddresses} | ForEach-Object {
    Write-Output ("IPs: {0}" -f ($_.IPAddresses -join ', '))
}
Write-Output ""
Write-Output "=== PING TEST ==="
foreach ($ip in @('192.168.150.12','192.168.150.13','192.168.150.14')) {
    $r = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue
    if ($r) { Write-Output "$ip : REACHABLE" } else { Write-Output "$ip : no response" }
}
Write-Output ""
Write-Output "=== OS DISK CONTENTS (read-only mount) ==="
$osDisk = Get-VMHardDisk -VMName $vmName | Where-Object { $_.ControllerNumber -eq 0 } | Select-Object -First 1
if ($osDisk) {
    $mounted = $false
    try {
        Mount-VHD -Path $osDisk.Path -ReadOnly -ErrorAction Stop
        $mounted = $true
        $vol = Get-VHD -Path $osDisk.Path | Get-VHDPartition | Where-Object { $_.DriveLetter }
        if ($vol) {
            $letter = $vol.DriveLetter
            Write-Output "Mounted at $letter`:"
            foreach ($probe in @("$letter`\Windows\System32\ntoskrnl.exe","$letter`\Windows\System32\config\SOFTWARE","$letter`\EFI","$letter`\sources")) {
                if (Test-Path $probe) { Write-Output "  PRESENT: $probe" } else { Write-Output "  absent: $probe" }
            }
            if (Test-Path "$letter`\Windows\System32\config\SOFTWARE") {
                Write-Output "--- ProductName from guest SOFTWARE hive ---"
                $hive = "$letter`\Windows\System32\config\SOFTWARE"
                try {
                    $reg = Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SYSTEM\MountedDevices" -ErrorAction Stop
                } catch {}
            }
        } else {
            Write-Output "No drive letter assigned to any partition."
            Get-VHD -Path $osDisk.Path | Get-VHDPartition | ForEach-Object { Write-Output ("  Partition {0} type {1} size {2} GB" -f $_.PartitionNumber, $_.Type, [math]::Round($_.Size/1GB,1)) }
        }
    } catch {
        Write-Output "Mount failed: $($_.Exception.Message)"
    } finally {
        if ($mounted) { try { Dismount-VHD -Path $osDisk.Path; Write-Output "Dismounted OK." } catch { Write-Output "Dismount failed: $($_.Exception.Message)" } }
    }
} else { Write-Output "No Controller 0 disk found." }