$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$start = Get-Date
for ($i = 1; $i -le 9; $i++) {
  $u = (Get-VM -Name BWANA-DC02).Uptime
  Write-Output ("[t+{0}m] dc02_uptime={1}" -f $i, $u)
  try {
    $r = Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
      $d = $null
      try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { $d = 'NONE' }
      $d
    } -ErrorAction Stop
    Write-Output ('   dc02_domain=' + $r)
    if ($r -eq 'ad.bwanakhasu.one') { Write-Output 'DC02-PROMOTED'; break }
  } catch { Write-Output ('   dc02: ' + $_.Exception.Message) }
  if ($i -lt 9) { Start-Sleep -Seconds 60 }
}
Write-Output 'DONE'
