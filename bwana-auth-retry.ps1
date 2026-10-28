Start-Sleep -Seconds 90
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$tried = @()
foreach ($u in @('Administrator', 'BWANA\Administrator', 'Administrator@ad.bwanakhasu.one')) {
  $cred = New-Object System.Management.Automation.PSCredential($u, $sec)
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
      $d = $null; try { $d = (Get-ADDomain -ErrorAction Stop).DNSRoot } catch {}
      $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
      [pscustomobject]@{ User = $using:u; Domain = $(if ($d) { $d } else { 'NONE' }); Up = "$($up.Hours)h$($up.Minutes)m" }
    } -ErrorAction Stop
    Write-Output ("AUTH-OK as {0}: domain={1} up={2}" -f $r.User, $r.Domain, $r.Up)
    if ($r.Domain -eq 'ad.bwanakhasu.one') { Write-Output 'FOREST-READY' }
    break
  } catch { $tried += ($u + ': ' + $_.Exception.Message) }
}
$tried | Write-Output
Write-Output 'DONE'
