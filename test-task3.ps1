$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
for ($i = 1; $i -le 8; $i++) {
  $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    $t = Get-ScheduledTask -TaskName 'Bwana-AD-Backup'
    $inf = Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup'
    [pscustomobject]@{ State = [string]$t.State; Result = ('0x{0:X8}' -f $inf.LastTaskResult) }
  } -ErrorAction Continue
  Write-Output ("[{0}] state={1} result={2}" -f (Get-Date -Format 'HH:mm:ss'), $r.State, $r.Result)
  if ($r.State -eq 'Ready') { break }
  Start-Sleep -Seconds 45
}
Write-Output '=== full log ==='
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Get-Content 'C:\BwanaBackup.log' -ErrorAction SilentlyContinue
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
