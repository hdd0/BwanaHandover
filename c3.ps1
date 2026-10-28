$ErrorActionPreference = 'Continue'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$users = @('BWANA\Administrator','Administrator@ad.bwanakhasu.one')
$ok = $null
foreach ($u in $users) {
  $cred = New-Object System.Management.Automation.PSCredential($u, $sec)
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
      $d = $null
      try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { $d = 'NONE' }
      $dc = $null
      try { $dc = (Get-ADDomainController -Identity $env:COMPUTERNAME -ErrorAction Stop).HostName } catch { $dc = 'ERR' }
      [pscustomobject]@{ Who = (whoami); D = $d; DC = $dc }
    } -ErrorAction Stop
    Write-Output ("OK as " + $u + " | who=" + $r.Who + " | domain=" + $r.D + " | dc=" + $r.DC)
    $ok = $u
    break
  } catch { Write-Output ("FAIL " + $u + " : " + $_.Exception.Message) }
}
if ($ok) { Set-Content 'C:\STEP\unattend\secrets\dc-cred-user.txt' $ok; Write-Output 'WORKING-CRED-SAVED' }
