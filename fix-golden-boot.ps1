$vmName = 'BWANA-GOLDEN-SRC'
$vm = Get-VM -Name $vmName

# Get bootable devices
$dvd = $vm.DVDDrives | Select-Object -First 1
$hdd = $vm.HardDrives | Where-Object { $_.Path -like '*BWANA-GOLDEN-SRC.vhdx' } | Select-Object -First 1
$net = Get-VMNetworkAdapter -VMName $vmName | Select-Object -First 1

"DVD: $($dvd | Out-String)"
"HDD: $($hdd | Out-String)"
"NET: $($net | Out-String)"

if ($dvd -and $hdd -and $net) {
    "Setting boot order: DVD -> HDD -> NET"
    Set-VMFirmware -VMName $vmName -BootOrder $dvd, $hdd, $net
} else {
    "Missing device. Aborting."
    exit 1
}

"New boot order:"
Get-VMFirmware -VMName $vmName | Select-Object -ExpandProperty BootOrder | ForEach-Object { $_ | Select-Object Device, BootType | Format-List }
