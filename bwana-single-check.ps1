$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
try {
  $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    $st = $null; try { $st = Get-DscConfigurationStatus -ErrorAction Stop } catch {}
    $d = $null; try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch {}
    $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    [pscustomobject]@{ N = $(if ($st) { $st.NumberOfResources } else { '?' }); Status = $(if ($st) { [string]$st.Status } else { '?' }); Domain = $(if ($d) { $d } else { 'NONE' }); Up = "$($up.Hours)h$($up.Minutes)m" }
  } -ErrorAction Stop
  Write-Output ("res={0} dsc={1} domain={2} up={3}" -f $r.N, $r.Status, $r.Domain, $r.Up)
} catch { Write-Output ('QUERY: ' + $_.Exception.Message) }
Write-Output 'DONE'
