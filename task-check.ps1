$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  $t = Get-ScheduledTask -TaskName 'Bwana-AD-Backup'
  $i = Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup'
  Write-Output ('State=' + $t.State)
  Write-Output ('LastRun=' + $i.LastRunTime)
  Write-Output ('LastTaskResult=' + $i.LastTaskResult + ' (0x{0:X8})' -f $i.LastTaskResult)
  Write-Output '--- log tail ---'
  Get-Content 'C:\BwanaBackup.log' -EA SilentlyContinue | Select-Object -Last 8 | ForEach-Object { Write-Output $_ }
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
