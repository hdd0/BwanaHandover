foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $hb = Get-VMIntegrationService -VMName $vm | Where-Object { $_.Name -like '*Heartbeat*' }
  $ps = Get-VMIntegrationService -VMName $vm | Where-Object { $_.Name -like '*PowerShell*' -or $_.Name -like '*Guest*' }
  Write-Output ($vm + ' heartbeat=' + $hb.PrimaryStatusDescription + ' enabled=' + $hb.Enabled)
  $ps | ForEach-Object { Write-Output ('  ' + $_.Name + '=' + $_.PrimaryStatusDescription) }
}
