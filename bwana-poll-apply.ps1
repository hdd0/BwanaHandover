$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
for ($i = 1; $i -le 9; $i++) {
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
      $st = $null; try { $st = Get-DscConfigurationStatus -ErrorAction Stop } catch {}
      $d = $null; try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch {}
      $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
      $adds = 'UNK'; try { $adds = (Get-WindowsFeature AD-Domain-Services -ErrorAction Stop).Installed } catch {}
      [pscustomobject]@{ N = $(if ($st) { $st.NumberOfResources } else { '?' }); Status = $(if ($st) { $st.Status } else { '?' }); Domain = $(if ($d) { $d } else { 'NONE' }); ADDS = $adds; Up = "$($up.Hours)h$($up.Minutes)m" }
    } -ErrorAction Stop
    Write-Output ("[t+{0}m] res={1} dsc={2} domain={3} adds={4} up={5}" -f $i, $r.N, $r.Status, $r.Domain, $r.ADDS, $r.Up)
    if ($r.Domain -eq 'ad.bwanakhasu.one') { Write-Output 'FOREST-READY'; break }
  } catch { Write-Output ("[t+{0}m] SESSION-DROP (likely reboot): " -f $i + $_.Exception.Message) }
  if ($i -lt 9) { Start-Sleep -Seconds 60 }
}
