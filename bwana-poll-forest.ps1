$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
Write-Output 'waiting 300s for forest install...'
Start-Sleep -Seconds 300
for ($i = 1; $i -le 6; $i++) {
  try {
    $r = Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
      try { 'DOMAIN=' + (Get-ADDomain -ErrorAction Stop).DNSRoot + ' NETBIOS=' + (Get-ADDomain).NetBIOSName }
      catch { 'DOMAIN=NONE' }
      'UPTIME=' + ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime)
    } -ErrorAction Stop
    Write-Output ("[t+{0}m] " -f ($i + 5) + ($r -join ' '))
    if ($r -match 'DOMAIN=ad\.') { Write-Output 'FOREST-READY'; break }
  } catch { Write-Output ("[t+{0}m] UNREACHABLE: " -f ($i + 5) + $_.Exception.Message) }
  if ($i -lt 6) { Start-Sleep -Seconds 60 }
}
