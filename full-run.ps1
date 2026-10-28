$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $bsec -AsPlainText -Force))
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw)))
Write-Output '=== DC01 direct run, SystemState ENABLED (full chain) ==='
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B, $C)
  [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
  & 'C:\backup-dc.ps1' -DCName $env:COMPUTERNAME -ShareRoot '\\192.168.150.1\BwanaBackups' -ShareCredential $C
} -ArgumentList $bk64, $bcred -ErrorAction Continue | Write-Output
Write-Output 'DONE'
