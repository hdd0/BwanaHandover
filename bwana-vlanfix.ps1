$ErrorActionPreference = 'Stop'
$sw = 'BWANA-AD-LAN'
$a = Get-VMNetworkAdapter -ManagementOS | Where-Object { $_.SwitchName -eq $sw } | Select-Object -First 1
if (-not $a) { Write-Output 'MGMT-ADAPTER-NOT-FOUND'; exit 1 }
Write-Output ('mgmt adapter: name=' + $a.Name + ' switch=' + $a.SwitchName)
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $a.Name -Access -VlanId 150
Get-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName $a.Name | Select-Object Name, AccessVlanId, OperationMode | Out-String | Write-Output
Write-Output 'waiting 15s for L2 settle...'
Start-Sleep -Seconds 15
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
      [pscustomobject]@{ GW = (Test-Connection '192.168.150.1' -Count 2 -Quiet); EXT = (Test-Connection '1.1.1.1' -Count 2 -Quiet) }
    } -ErrorAction Stop
    Write-Output ($vm + ': gw=' + $r.GW + ' ext=' + $r.EXT)
  } catch { Write-Output ($vm + ': FAILED: ' + $_.Exception.Message) }
}
