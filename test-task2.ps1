$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Remove-Item 'C:\BwanaBackup.log' -Force -ErrorAction SilentlyContinue
  Start-ScheduledTask -TaskName 'Bwana-AD-Backup'
  Write-Output 'TASK-STARTED'
} -ErrorAction Continue | Write-Output
for ($i = 1; $i -le 14; $i++) {
  Start-Sleep -Seconds 60
  $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    $t = Get-ScheduledTask -TaskName 'Bwana-AD-Backup'
    $i = Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup'
    [pscustomobject]@{ State = [string]$t.State; Result = ('0x{0:X8}' -f $i.LastTaskResult) }
  } -ErrorAction Continue
  Write-Output ("[t+{0}m] state={1} result={2}" -f $i, $r.State, $r.Result)
  if ($r.State -eq 'Ready' -and $i -gt 1) { break }
}
Write-Output '=== task log ==='
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Get-Content 'C:\BwanaBackup.log' -ErrorAction SilentlyContinue | Select-Object -Last 20
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
