$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $bsec -AsPlainText -Force))
Write-Output ('HOST-side expected password length: ' + ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))).Length)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($C)
  Write-Output ('GUEST received user: ' + $C.UserName)
  $p = $C.GetNetworkCredential().Password
  Write-Output ('GUEST GetNetworkCredential().Password length: ' + $p.Length)
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($C.Password)
  $p2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
  [void][Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  Write-Output ('GUEST SecureString->plain length: ' + $p2.Length)
  $clix = Import-Clixml 'C:\BwanaSvcCred.xml'
  Write-Output ('GUEST clixml user: ' + $clix.UserName + ' pw length: ' + $clix.GetNetworkCredential().Password.Length)
} -ArgumentList $bcred -ErrorAction Continue | Write-Output
Write-Output 'DONE'
