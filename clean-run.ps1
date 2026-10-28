$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Remove-Item 'C:\BwanaBackup.log' -Force -EA SilentlyContinue
  Start-ScheduledTask -TaskName 'Bwana-AD-Backup'
  Write-Output 'CLEAN-RUN-STARTED'
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
