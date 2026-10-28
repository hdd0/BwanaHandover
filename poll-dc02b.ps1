$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
for ($i = 1; $i -le 9; $i++) {
  $u = (Get-VM -Name BWANA-DC02).Uptime
  $dom = 'unqueried'
  try {
    $dom = Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
      $d = $null; try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { $d = 'NONE' }; $d
    } -ErrorAction Stop
  } catch { $dom = 'UNREACHABLE' }
  Write-Output ("[t+{0}m] uptime={1} domain={2}" -f $i, $u, $dom)
  if ($dom -eq 'ad.bwanakhasu.one') { Write-Output 'DC02-PROMOTED'; break }
  if ($i -lt 9) { Start-Sleep -Seconds 60 }
}
Write-Output 'DONE'
