$fw = Get-VMFirmware -VMName BWANA-DC01
Write-Output ("FirstBootDevice=" + $fw.FirstBootDevice)
Write-Output "--- BootOrder raw ---"
$fw.BootOrder | Format-List * | Out-String | Write-Output
Write-Output "--- BootOrder[0] type ---"
$b0 = $fw.BootOrder | Select-Object -First 1
Write-Output ("b0.ToString=" + $b0.ToString())
Write-Output ("b0.GetType=" + $b0.GetType().FullName)
$b0 | Get-Member | Out-String | Write-Output
