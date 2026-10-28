$vm = 'BWANA-GOLDEN-SRC'
Write-Host "--- VM adapter ---"
Get-VMNetworkAdapter -VMName $vm | Format-List Status, IPAddresses

Write-Host "--- DC01 DHCP role ---"
foreach ($dc in '192.168.150.10','192.168.150.11') {
  try {
    $s = Invoke-Command -ComputerName $dc -ScriptBlock {
      $dhcp = Get-WindowsFeature -Name DHCP -ErrorAction SilentlyContinue
      [pscustomobject]@{
        Host   = $env:COMPUTERNAME
        DHCP   = $dhcp.InstallState
        Scopes = ((Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | ForEach-Object { "$($_.ScopeId):$($_.StartRange)-$($_.EndRange)" }) -join ', ')
      }
    } -ErrorAction Stop
    $s | Format-List
  } catch {
    Write-Host "$dc : FAILED - $($_.Exception.Message)"
  }
}