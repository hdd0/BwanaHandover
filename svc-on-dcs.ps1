$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $plain -AsPlainText -Force))
$register = Get-Content 'C:\STEP\BwanaAD\scripts\register-backup-task.ps1' -Raw
$backup   = Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw
$rg64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($register))
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($backup))

foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($R, $B, $C)
    Stop-ScheduledTask -TaskName 'Bwana-AD-Backup' -ErrorAction SilentlyContinue
    Get-Process wbadmin -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    [IO.File]::WriteAllText('C:\register-backup-task.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($R)))
    [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
    $u = 'BwanaBackupSvc'
    $s = ConvertTo-SecureString $C.GetNetworkCredential().Password -AsPlainText -Force
    if (Get-LocalUser -Name $u -EA SilentlyContinue) { Set-LocalUser -Name $u -Password $s | Out-Null; Write-Output 'SVC-UPDATED' }
    else { New-LocalUser -Name $u -Password $s -Description 'Bwana backup runner' | Out-Null; Write-Output 'SVC-CREATED' }
    & net.exe user $u /passwordchg:no /active:yes | Out-Null
    Add-LocalGroupMember -Group 'Backup Operators' -Member $u -EA SilentlyContinue
    Write-Output ('InBackupOperators=' + ((Get-LocalGroupMember -Group 'Backup Operators' -EA SilentlyContinue).Name -contains $u))
    $C | Export-Clixml 'C:\BwanaSvcCred.xml' -Force
    & 'C:\register-backup-task.ps1' -DomainAdminCredential $C
  } -ArgumentList $rg64, $bk64, $bcred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
