$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw)))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  Stop-ScheduledTask -TaskName 'Bwana-AD-Backup' -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 3
  Get-Process wbadmin -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
  Write-Output 'SCRIPT-UPDATED, STUCK-WBADMIN-KILLED'
} -ArgumentList $bk64 -ErrorAction Continue | Write-Output
Start-Sleep -Seconds 5
Write-Output 'DONE'
