$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
foreach ($u in @('Administrator@ad.bwanakhasu.one','BWANA\Administrator')) {
  $c = New-Object System.Management.Automation.PSCredential($u, $sec)
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $c -ScriptBlock { whoami } -EA Stop
    Write-Output ("OK as $u -> $r")
  } catch { Write-Output ("FAIL $u : " + $_.Exception.Message) }
}
Write-Output 'DONE'
