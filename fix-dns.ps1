$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)

# DC02: full DNS list + forwarders, then reboot to register records
try {
  Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
    $ad = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses @('192.168.150.10','192.168.150.11')
    try { Set-DnsServerForwarder -IPAddress @('1.1.1.1','8.8.8.8') -ErrorAction Stop } catch { 'FWD-ERR ' + $_.Exception.Message }
    Write-Output ('DC02-DNS=' + ((Get-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -AddressFamily IPv4).ServerAddresses -join ','))
    Restart-Computer -Force
  } -ErrorAction Stop | Write-Output
  Write-Output 'DC02-REBOOT-SENT'
} catch { Write-Output ('DC02-ERR: ' + $_.Exception.Message) }

# DC01: forwarders with correct read-back
try {
  Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    try { Set-DnsServerForwarder -IPAddress @('1.1.1.1','8.8.8.8') -ErrorAction Stop } catch { 'FWD1-ERR ' + $_.Exception.Message }
    Write-Output ('DC01-FWD=' + ((Get-DnsServerForwarder -ErrorAction SilentlyContinue | ForEach-Object { $_.RemoteServer }) -join ','))
  } -ErrorAction Stop | Write-Output
} catch { Write-Output ('DC01-ERR: ' + $_.Exception.Message) }
