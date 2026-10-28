$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- log exists? ---'
  Write-Output ('log=' + (Test-Path 'C:\BwanaBackup.log'))
  Get-Content 'C:\BwanaBackup.log' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_ }
  Write-Output '--- task info ---'
  Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup' | Select-Object LastRunTime, LastTaskResult | Format-List | Out-String | Write-Output
  Write-Output '--- run backup-dc.ps1 synchronously to see real output ---'
  $b = Import-Clixml 'C:\BwanaSvcCred.xml'
  & 'C:\backup-dc.ps1' -DCName $env:COMPUTERNAME -ShareRoot '\\192.168.150.1\BwanaBackups' -ShareCredential $b -SkipSystemState
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
