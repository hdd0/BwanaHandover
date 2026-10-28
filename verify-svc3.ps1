$ErrorActionPreference = 'Continue'
$user = 'BwanaBackupSvc'
$saved = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($saved))
$c = New-Object System.Management.Automation.PSCredential($user, (ConvertTo-SecureString $plain -AsPlainText -Force))
try {
  New-PSDrive -Name BKTest -PSProvider FileSystem -Root '\\localhost\BwanaBackups' -Credential $c -Scope Script -ErrorAction Stop | Out-Null
  Set-Content 'BKTest:\hello.txt' 'smb-ok' -Force
  Write-Output ('SMB-OK: ' + (Get-Content 'BKTest:\hello.txt'))
  Remove-PSDrive BKTest -Force
} catch { Write-Output ('SMB-ERR: ' + $_.Exception.Message) }
Write-Output 'DONE'
