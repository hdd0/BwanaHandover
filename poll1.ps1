# poll install progress (5 min wait)
Start-Sleep 240
Get-VM BWANA-DC01, BWANA-DC02 | Format-Table Name,State,Uptime | Out-String | Write-Output
Get-VMIntegrationService -VMName BWANA-DC01, BWANA-DC02 | Where-Object { $_.Name -like '*Heartbeat*' } | Format-Table VMName,PrimaryStatusDescription | Out-String | Write-Output
Write-Output DONE-POLL1
