$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Write-Output '=== DC02 ==='
Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
  Write-Output ('HOST=' + $env:COMPUTERNAME + ' DOMAIN=' + (Get-ADDomain).DNSRoot)
  Write-Output ('NTDS=' + (Get-Service NTDS).Status + ' DNS=' + (Get-Service DNS).Status)
  $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.150.*' }
  Write-Output ('IP=' + $ip.IPAddress + ' DNSLIST=' + ((Get-DnsClientServerAddress -InterfaceIndex $ip.InterfaceIndex -AddressFamily IPv4).ServerAddresses -join ','))
} -ErrorAction Continue | Write-Output
Write-Output '=== DC01 replication + GC ==='
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Start-Sleep -Seconds 20
  Get-ADDomainController -Filter * | Select-Object HostName, IPv4Address, IsGlobalCatalog | Format-Table -AutoSize | Out-String | Write-Output
  Write-Output '--- repadmin showrepl tail ---'
  (repadmin /showrepl * /csv 2>&1 | Select-Object -First 12 | Out-String)
  Write-Output '--- dcdiag summary ---'
  (dcdiag /e /c 2>&1 | Select-Object -Last 15 | Out-String)
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
