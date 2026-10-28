$fw = Get-VMFirmware -VMName BWANA-DC01
$fw.BootOrder | ForEach-Object {
    Write-Output "Type: $($_.BootType), Device: $($_.Device.Name), DevType: $($_.Device.GetType().Name)"
}