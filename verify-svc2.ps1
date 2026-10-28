$ErrorActionPreference = 'Continue'
$user = 'BwanaBackupSvc'
$wmi = Get-WmiObject -Class Win32_UserAccount -Filter ("Name='" + $user + "'")
$wmi.PasswordExpires = $false
$wmi.Put() | Out-Null
& net.exe user $user /passwordchg:no | Out-Null
Write-Output 'FLAGS-SET'
# Real test: SMB auth to the share from this host
$saved = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($saved))
$c = New-Object System.Management.Automation.PSCredential($user, (ConvertTo-SecureString $plain -AsPlainText -Force))
try {
  $t = Test-Path '\\localhost\BwanaBackups' -Credential $c -ErrorAction Stop
  Write-Output ('SMB-TEST-RESULT=' + $t)
} catch { Write-Output ('SMB-TEST-ERR: ' + $_.Exception.Message) }
Write-Output 'DONE'
