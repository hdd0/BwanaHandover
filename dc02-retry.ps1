$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$upn = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
  Remove-Item 'C:\BwanaBackup.log' -Force -EA SilentlyContinue
  Start-ScheduledTask -TaskName 'Bwana-AD-Backup'
  Write-Output 'DC02-RETRY-STARTED'
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
