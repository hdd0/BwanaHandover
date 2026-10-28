$vmName = 'BWANA-EXCH-01'
$dvd = Get-VMDvdDrive -VMName $vmName
$hdd = Get-VMHardDiskDrive -VMName $vmName | Select-Object -First 1
$net = Get-VMNetworkAdapter -VMName $vmName
Set-VMFirmware -VMName $vmName -BootOrder $dvd,$hdd,$net
Write-Output "BootOrder set"
Get-VMFirmware -VMName $vmName | Select-Object BootOrder