$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
try {
  $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    $u = Get-ADUser -LDAPFilter '(sAMAccountName=Administrator)' -Properties LockedOut, lockoutTime, badPwdCount
    'DC01-AUTH-OK LockedOut=' + $u.LockedOut + ' badPwdCount=' + $u.badPwdCount
  } -ErrorAction Stop | Write-Output
} catch { Write-Output ('DC01-AUTH-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
