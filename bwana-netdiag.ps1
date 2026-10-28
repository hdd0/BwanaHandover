$ErrorActionPreference = 'Stop'
Write-Output '--- HOST ---'
Get-NetIPAddress -IPAddress '192.168.150.1' -ErrorAction SilentlyContinue | Select-Object IPAddress, InterfaceAlias | Out-String | Write-Output
Get-NetNat -Name 'BWANA-AD-NAT' -ErrorAction SilentlyContinue | Select-Object Name, InternalIPInterfaceAddressPrefix | Out-String | Write-Output
Get-VMNetworkAdapterVlan -VMName BWANA-DC01,BWANA-DC02 | Select-Object VMName, AccessVlanId, OperationMode | Out-String | Write-Output
Write-Output '--- MGMT OS vNIC VLAN ---'
Get-VMNetworkAdapterVlan -ManagementOS | Select-Object VMName, Name, AccessVlanId, OperationMode | Out-String | Write-Output
Write-Output '--- GUEST ping gateway ---'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
      $gw = Test-Connection -ComputerName '192.168.150.1' -Count 2 -Quiet
      $ext = Test-Connection -ComputerName '1.1.1.1' -Count 2 -Quiet
      $dns = (Resolve-DnsName 'passtest' -Server '1.1.1.1' -ErrorAction SilentlyContinue | Measure-Object).Count
      [pscustomobject]@{ GW = $gw; EXT = $ext; DNS = $dns }
    } -ErrorAction Stop
    Write-Output ($vm + ': gw=' + $r.GW + ' ext=' + $r.EXT + ' dnsrows=' + $r.DNS)
  } catch { Write-Output ($vm + ': FAILED: ' + $_.Exception.Message) }
}
