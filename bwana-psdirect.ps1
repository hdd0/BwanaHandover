$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
if (-not (Test-Path $secFile)) { Write-Output 'NO-SECRETS-FILE'; exit 2 }
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
      $os = Get-CimInstance Win32_OperatingSystem
      $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '127.*' } | Select-Object -ExpandProperty IPAddress) -join ','
      [pscustomobject]@{ Host = $env:COMPUTERNAME; OS = $os.Caption; Build = $os.BuildNumber; Boot = $os.LastBootUpTime; IP = $ip }
    } -ErrorAction Stop
    Write-Output ($vm + ': PS-DIRECT OK host=' + $r.Host + ' os="' + $r.OS + '" build=' + $r.Build + ' boot=' + $r.Boot + ' ip=' + $r.IP)
  } catch { Write-Output ($vm + ': PS-DIRECT FAILED: ' + $_.Exception.Message) }
}
