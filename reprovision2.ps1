$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$rg64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\register-backup-task.ps1' -Raw)))
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw)))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($R, $B, $DA, $P)
    Stop-ScheduledTask -TaskName 'Bwana-AD-Backup' -EA SilentlyContinue
    Get-Process wbadmin -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    [IO.File]::WriteAllText('C:\register-backup-task.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($R)))
    [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
    Remove-Item 'C:\BwanaSvcCred.xml' -Force -EA SilentlyContinue
    & 'C:\register-backup-task.ps1' -DomainAdminCredential $DA -ShareUser 'BwanaBackupSvc' -SharePassword $P
    Write-Output '--- wrapper ---'
    Get-Content 'C:\BwanaBackupTask.ps1' | ForEach-Object { Write-Output $_ }
  } -ArgumentList $rg64, $bk64, $cred, $plain -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
