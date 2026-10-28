foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $dvd = Get-VMDvdDrive -VMName $vm -ErrorAction Stop | Select-Object -First 1
    Set-VMFirmware -VMName $vm -FirstBootDevice $dvd -ErrorAction Stop
    Write-Output ("FIXED {0} DVD first" -f $vm)
  } catch { Write-Output ("FAILED {0}: {1}" -f $vm, $_.Exception.Message) }
}
Get-VMFirmware -VMName BWANA-DC01 | Select-Object -ExpandProperty BootOrder | Out-String | Write-Output
