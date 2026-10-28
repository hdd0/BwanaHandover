$ErrorActionPreference = 'Continue'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
try {
  $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    $d = $null; try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch {}
    $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    [pscustomobject]@{ D = $(if ($d) { $d } else { 'NONE' }); Up = "$($up.Hours)h$($up.Minutes)m" }
  } -ErrorAction Stop
  Write-Output ("LOCAL-OK domain=" + $r.D + " up=" + $r.Up)
} catch { Write-Output ('LOCAL-FAIL: ' + $_.Exception.Message) }
