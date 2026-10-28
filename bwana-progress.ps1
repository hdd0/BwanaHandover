foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $v = Get-VM -Name $vm
  $hd = Get-VMHardDiskDrive -VMName $vm | Where-Object { $_.Path -notlike '*answer-*.vhdx' } | Select-Object -First 1
  $sz = (Get-Item $hd.Path).Length
  $hb = (Get-VMIntegrationService -VMName $vm | Where-Object { $_.Name -like '*Heartbeat*' }).PrimaryStatusDescription
  Write-Output ("{0} state={1} uptime={2} heartbeat={3} osdisk_bytes={4}" -f $vm, $v.State, $v.Uptime, $hb, $sz)
}
