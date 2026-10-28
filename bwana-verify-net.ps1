$ErrorActionPreference = 'Stop'
Write-Output 'waiting 100s for reboot...'
Start-Sleep -Seconds 100
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
      $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.150.*' } | Select-Object -ExpandProperty IPAddress) -join ','
      $net = Test-Connection -ComputerName '1.1.1.1' -Count 2 -Quiet
      $dsc = (Get-Module -ListAvailable | Select-Object -ExpandProperty Name)
      [pscustomobject]@{ Host = $env:COMPUTERNAME; IP = $ip; PingGW = $net; DSC = ($dsc -join ',') }
    } -ErrorAction Stop
    Write-Output ($vm + ': host=' + $r.Host + ' ip=' + $r.IP + ' ping1.1.1.1=' + $r.PingGW + ' modules=[' + $r.DSC + ']')
  } catch { Write-Output ($vm + ': FAILED: ' + $_.Exception.Message) }
}
