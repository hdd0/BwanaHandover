$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$plan = @(
  @{ VM = 'BWANA-DC01'; Name = 'BWANA-DC01'; IP = '192.168.150.10' },
  @{ VM = 'BWANA-DC02'; Name = 'BWANA-DC02'; IP = '192.168.150.11' }
)
foreach ($p in $plan) {
  try {
    Invoke-Command -VMName $p.VM -Credential $cred -ScriptBlock {
      param($NewName, $NewIP)
      $ad = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
      Rename-Computer -NewName $NewName -Force
      Remove-NetIPAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
      Remove-NetRoute -InterfaceIndex $ad.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
      New-NetIPAddress -InterfaceIndex $ad.ifIndex -IPAddress $NewIP -PrefixLength 24 -DefaultGateway '192.168.150.1' | Out-Null
      Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses '1.1.1.1'
      Set-TimeZone -Id 'South Africa Standard Time'
      "RENAMED to $NewName IP $NewIP on $($ad.Name)"
    } -ArgumentList $p.Name, $p.IP -ErrorAction Stop | Write-Output
    Invoke-Command -VMName $p.VM -Credential $cred -ScriptBlock { Restart-Computer -Force } -ErrorAction SilentlyContinue
    Write-Output ($p.VM + ': rebooting')
  } catch { Write-Output ($p.VM + ': FAILED: ' + $_.Exception.Message) }
}
