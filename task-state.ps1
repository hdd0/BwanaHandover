$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  $t = Get-ScheduledTask -TaskName 'Bwana-AD-Backup'
  $i = Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup'
  Write-Output ('STATE=' + $t.State + ' LASTRUN=' + $i.LastRunTime + ' RESULT=' + $i.Result)
  Write-Output ('0x' + ('{0:X8}' -f $i.LastTaskResult))
  Write-Output '=== log ==='
  if (Test-Path 'C:\BwanaBackup.log') {
    Get-Content 'C:\BwanaBackup.log' | Select-Object -Last 20 | ForEach-Object { Write-Output $_ }
  } else { Write-Output 'no-log' }
  Write-Output '=== stage dir ==='
  Get-ChildItem 'C:\BwanaBackupStage' -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime | Format-Table -AutoSize | Out-String | Write-Output
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
