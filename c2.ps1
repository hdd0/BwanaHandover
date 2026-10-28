$ErrorActionPreference = 'Continue'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$users = @('BWANA\Administrator','Administrator@ad.bwanakhasu.one','AD.BWANAKHASU.ONE\Administrator')
$ok = $null
foreach ($u in $users) {
  $cred = New-Object System.Management.Automation.PSCredential($u, $sec)
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
      [pscustomobject]@{ Who = (whoami); D = (try { (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { 'NONE' }) }
    } -ErrorAction Stop
    Write-Output ("OK as " + $u + " who=" + $r.Who + " domain=" + $r.D)
    $ok = $cred
    break
  } catch { Write-Output ("FAIL " + $u + " : " + $_.Exception.Message) }
}
if ($ok) { $ok.GetNetworkCredential().UserName | Set-Content 'C:\STEP\unattend\secrets\dc-cred-user.txt'; Write-Output 'WORKING-CRED-SAVED' }
