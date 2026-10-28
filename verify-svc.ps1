$ErrorActionPreference = 'Continue'
$user = 'BwanaBackupSvc'
# Ensure the account can be used for network logon
& net.exe user $user /passwordchg:no /active:yes | Out-String | Write-Output
$u = Get-LocalUser -Name $user
Write-Output ('PasswordExpires=' + $u.PasswordExpires + ' Expires=' + $u.AccountExpires + ' Enabled=' + $u.Enabled)
# Verify the stored DPAPI password actually authenticates
$saved = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($saved))
$test = ConvertTo-SecureString $plain -AsPlainText -Force
$c = New-Object System.Management.Automation.PSCredential($user, $test)
try {
  $lpc = New-PSSession -ComputerName localhost -Credential $c -ErrorAction Stop
  Write-Output 'LOGON-TEST-OK'
  Remove-PSSession $lpc
} catch { Write-Output ('LOGON-TEST-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
