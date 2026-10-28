$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$upn = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
for ($i = 1; $i -le 10; $i++) {
  $r = Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
    $t = Get-ScheduledTask -TaskName 'Bwana-AD-Backup'
    $in = Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup'
    [pscustomobject]@{ State = [string]$t.State; Result = ('0x{0:X8}' -f $in.LastTaskResult); LastRun = $in.LastRunTime }
  } -ErrorAction Continue
  Write-Output ("[{0}] state={1} result={2} lastrun={3}" -f (Get-Date -Format 'HH:mm:ss'), $r.State, $r.Result, $r.LastRun)
  if ($r.State -eq 'Ready') { break }
  Start-Sleep -Seconds 60
}
Write-Output '=== DC02 task log tail ==='
Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
  Get-Content 'C:\BwanaBackup.log' -EA SilentlyContinue | Select-Object -Last 14
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
