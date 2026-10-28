$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Write-Output '=== DC01 view ==='
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  $d = Get-ADDomain
  Write-Output ('DOMAIN=' + $d.DNSRoot + ' MODE=' + $d.DomainMode)
  $dcs = Get-ADDomainController -Filter * | Select-Object HostName, IPv4Address, IsGlobalCatalog, OperationStatus
  $dcs | Format-Table -AutoSize | Out-String | Write-Output
  Write-Output '--- DCLIST-CSV ---'
  (Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName) -join ','
  $fw = $null
  try { $fw = (Get-DnsServerForwarder -ErrorAction Stop | Select-Object -ExpandProperty IPAddressToString) -join ',' } catch { $fw = 'ERR' }
  Write-Output ('FWD=' + $fw)
  Write-Output '--- REPLSUMMARY ---'
  (repadmin /replsummary 2>&1 | Out-String)
} -ErrorAction Continue | Write-Output
Write-Output '=== DC02 view ==='
Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
  Write-Output ('HOST=' + $env:COMPUTERNAME)
  Write-Output ('DOMAIN=' + (Get-ADDomain).DNSRoot)
  Write-Output ('REBOOT-PENDING=' + (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'))
  $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.150.*' }
  Write-Output ('IP=' + $ip.IPAddress)
  Write-Output ('DNS=' + ((Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }).ServerAddresses -join ','))
} -ErrorAction Continue | Write-Output
