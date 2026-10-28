foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    Restart-VM -Name $vm -Force -ErrorAction Stop
    Write-Output ("RESTARTED " + $vm)
  } catch { Write-Output ("RESTART FAILED {0}: {1}" -f $vm, $_.Exception.Message) }
}
Start-Sleep -Seconds 15
Get-VM BWANA-DC01,BWANA-DC02 | Format-Table Name,State,Uptime | Out-String | Write-Output
