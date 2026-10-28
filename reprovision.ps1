$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $bsec -AsPlainText -Force))
$rg64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\register-backup-task.ps1' -Raw)))
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw)))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($R, $B, $DA, $BC)
    Stop-ScheduledTask -TaskName 'Bwana-AD-Backup' -EA SilentlyContinue
    Get-Process wbadmin -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    [IO.File]::WriteAllText('C:\register-backup-task.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($R)))
    [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
    $BC | Export-Clixml 'C:\BwanaSvcCred.xml' -Force
    & 'C:\register-backup-task.ps1' -DomainAdminCredential $DA
  } -ArgumentList $rg64, $bk64, $cred, $bcred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
