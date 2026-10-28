$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$upn = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw)))
Write-Output '=== deploy final script to DC02, start its task ==='
Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
  param($B)
  [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
  Remove-Item 'C:\BwanaBackup.log' -Force -EA SilentlyContinue
  Start-ScheduledTask -TaskName 'Bwana-AD-Backup'
  Write-Output 'DC02-TASK-STARTED'
} -ArgumentList $bk64 -ErrorAction Continue | Write-Output
for ($i = 1; $i -le 14; $i++) {
  Start-Sleep -Seconds 60
  $r = Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
    $t = Get-ScheduledTask -TaskName 'Bwana-AD-Backup'
    $in = Get-ScheduledTaskInfo -TaskName 'Bwana-AD-Backup'
    [pscustomobject]@{ State = [string]$t.State; Result = ('0x{0:X8}' -f $in.LastTaskResult) }
  } -ErrorAction Continue
  Write-Output ("[t+{0}m] state={1} result={2}" -f $i, $r.State, $r.Result)
  if ($r.State -eq 'Ready' -and $i -gt 1) { break }
}
Write-Output '=== DC02 task log ==='
Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
  Get-Content 'C:\BwanaBackup.log' -EA SilentlyContinue | Select-Object -Last 12
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
