$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$g = Get-ADGroup -LDAPFilter '(cn=Bwana-Admins)'
$g.SID.Value
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
$r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\getsid.ps1' $t -Force
  & 'C:\getsid.ps1'
} -ArgumentList $b64
Set-Content 'C:\Users\howar\AppData\Local\Temp\opencode\bwana-admins-sid.txt' ($r | Select-Object -First 1)
Write-Output ('Bwana-Admins SID=' + ($r | Select-Object -First 1))
