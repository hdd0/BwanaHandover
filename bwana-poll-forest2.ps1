$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
for ($i = 1; $i -le 9; $i++) {
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
      $d = $null; try { $d = Get-ADDomain -ErrorAction Stop } catch {}
      $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
      $dsc = $null; try { $dsc = Get-DscConfigurationStatus -ErrorAction Stop } catch {}
      [pscustomobject]@{ Domain = $(if ($d) { $d.DNSRoot } else { 'NONE' }); Uptime = "$($up.Hours)h$($up.Minutes)m"; DSC = $(if ($dsc) { "$($dsc.Status)" } else { 'UNKNOWN' }) }
    } -ErrorAction Stop
    Write-Output ("[t+{0}m] domain={1} uptime={2} dsc={3}" -f $i, $r.Domain, $r.Uptime, $r.DSC)
    if ($r.Domain -eq 'ad.bwanakhasu.one') { Write-Output 'FOREST-READY'; break }
  } catch { Write-Output ("[t+{0}m] UNREACHABLE: " -f $i + $_.Exception.Message) }
  if ($i -lt 9) { Start-Sleep -Seconds 60 }
}
