$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
param($Plain)
$ErrorActionPreference = 'Continue'
$root = '\\192.168.150.1\BwanaBackups'
$s = ConvertTo-SecureString $Plain -AsPlainText -Force
$mk = {
  param($u)
  $c = New-Object System.Management.Automation.PSCredential($u, (ConvertTo-SecureString $Plain -AsPlainText -Force))
  New-Object System.Management.Automation.PSCredential($c.UserName, $c.Password)
}
foreach ($u in @('BwanaBackupSvc', '192.168.150.1\BwanaBackupSvc', '.\BwanaBackupSvc', 'NDIRANDEONE\BwanaBackupSvc')) {
  $c = & $mk $u
  Write-Output ('--- user=' + $u)
  try {
    New-PSDrive -Name T1 -PSProvider FileSystem -Root $root -Credential $c -Scope Script -EA Stop | Out-Null
    Write-Output '  NEW-PSDRIVE-OK'
    Set-Content 'T1:\probe.txt' 'x' -Force -EA Stop
    Write-Output '  WRITE-OK'
    Remove-PSDrive T1 -Force -EA SilentlyContinue
  } catch { Write-Output ('  FAIL: ' + $_.Exception.Message) }
}
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B, $P)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\authtest2.ps1' $t -Force
  & 'C:\authtest2.ps1' -Plain $P
} -ArgumentList $b64, $plain -ErrorAction Continue | Write-Output
Write-Output 'DONE'
