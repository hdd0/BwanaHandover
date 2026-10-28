$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', $bsec)
$backup   = Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw
$register = Get-Content 'C:\STEP\BwanaAD\scripts\register-backup-task.ps1' -Raw
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($backup))
$rg64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($register))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== register on ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $R, $C)
    [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
    [IO.File]::WriteAllText('C:\register-backup-task.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($R)))
    & 'C:\register-backup-task.ps1' -ShareCredential $C
  } -ArgumentList $bk64, $rg64, $bcred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
