Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -notlike '169.254*' } |
  Select-Object InterfaceAlias, IPAddress, PrefixLength |
  Format-Table -AutoSize

Write-Host "--- DHCP server on host ---"
Get-DhcpServerv4BindingPolicy -ErrorAction SilentlyContinue | Out-Null
try {
  Get-DhcpServerv4Scope | Select-Object ScopeId, Name, StartRange, EndRange, SubnetMask | Format-Table -AutoSize
} catch { Write-Host "scope query failed: $_" }

Write-Host "--- reservations ---"
try {
  Get-DhcpServerv4Reservation | Select-Object ScopeId, IPAddress, ClientId, Name, Description | Format-Table -AutoSize
} catch { Write-Host "reservation query failed: $_" }

Write-Host "--- leases ---"
try {
  Get-DhcpServerv4Lease | Select-Object IPAddress, ClientId, HostName, AddressState | Format-Table -AutoSize
} catch { Write-Host "lease query failed: $_" }