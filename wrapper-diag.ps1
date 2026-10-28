$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- wrapper ---'
  Get-Content 'C:\BwanaBackupTask.ps1' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_ }
  Write-Output '--- task action ---'
  (Get-ScheduledTask -TaskName 'Bwana-AD-Backup').Actions | Format-List * | Out-String | Write-Output
  Write-Output '--- task info ---'
  Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup' | Select-Object LastRunTime, LastTaskResult, NumberOfMissedRuns | Format-List | Out-String | Write-Output
  Write-Output '--- TaskScheduler operational errors ---'
  Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' -MaxEvents 25 -ErrorAction SilentlyContinue |
    Where-Object { $_.TimeCreated -gt (Get-Date).AddMinutes(-20) -and $_.LevelDisplayName -in @('Error','Warning') } |
    Select-Object -First 5 TimeCreated, Id, Message | Format-List | Out-String | Write-Output
  Write-Output '--- run wrapper manually ---'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\BwanaBackupTask.ps1' -ErrorAction Continue 2>&1 | Select-Object -Last 8 | ForEach-Object { Write-Output $_ }
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
