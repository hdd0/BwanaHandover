# wait 3 min then check OS disk growth = proof Setup runs
Start-Sleep 180
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $hd = Get-VMHardDiskDrive -VMName $vm | Where-Object { $_.Path -notlike '*answer-*.vhdx' } | Select-Object -First 1
  $sz = (Get-Item $hd.Path).Length
  Write-Output ($vm + " osdisk_bytes=" + $sz)
}
Get-VMIntegrationService -VMName BWANA-DC01, BWANA-DC02 | Where-Object { $_.Name -like '*Heartbeat*' } | Format-Table VMName,PrimaryStatusDescription | Out-String | Write-Output
Write-Output DONE-GROWTH
