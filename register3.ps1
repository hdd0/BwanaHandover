$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', $bsec)
$register = Get-Content 'C:\STEP\BwanaAD\scripts\register-backup-task.ps1' -Raw
$rg64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($register))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== register on ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($R, $C, $DA)
    # stop any stale run first
    Stop-ScheduledTask -TaskName 'Bwana-AD-Backup' -ErrorAction SilentlyContinue
    [IO.File]::WriteAllText('C:\register-backup-task.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($R)))
    $C | Export-Clixml 'C:\BwanaSvcCred.xml' -Force
    & 'C:\register-backup-task.ps1' -DomainAdminCredential $DA
  } -ArgumentList $rg64, $bcred, $cred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
