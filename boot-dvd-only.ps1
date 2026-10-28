$vmName = 'BWANA-GOLDEN-SRC'
$vm = Get-VM -Name $vmName

$dvd = $vm.DVDDrives | Select-Object -First 1
$net = Get-VMNetworkAdapter -VMName $vmName | Select-Object -First 1

"Setting boot order: DVD only -> Network"
Set-VMFirmware -VMName $vmName -BootOrder $dvd, $net

Get-VMFirmware -VMName $vmName | Select-Object -ExpandProperty BootOrder | ForEach-Object {
    "  $($_.BootType): $($_.Device)"
}

Start-VM -Name $vmName
Start-Sleep -Seconds 3
$vm = Get-VM -Name $vmName
"State: $($vm.State), Uptime: $($vm.Uptime)"
