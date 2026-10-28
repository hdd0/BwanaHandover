$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output ('HOST=' + $env:COMPUTERNAME)
  $d = Get-ADDomain
  Write-Output ('DOMAIN=' + $d.DNSRoot + ' NETBIOS=' + $d.NetBIOSName + ' MODE=' + $d.DomainMode)
  Write-Output ('NETBIOSNAME=' + $d.NetBIOSName)
  $f = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
  Write-Output ('FORESTROOT=' + $f.RootDomain)
  Write-Output ('DCLIST=' + ((Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName) -join ','))
  $ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.150.*' }
  Write-Output ('IP=' + $ip.IPAddress + ' PREFIX=' + $ip.PrefixLength)
  Write-Output ('GW=' + ((Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue).NextHop))
  Write-Output ('DNS=' + ((Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses }).ServerAddresses -join ','))
  $fw = @()
  try { $fw = (Get-DnsServerForwarder -ErrorAction Stop).IPAddressToString } catch {}
  Write-Output ('FORWARDERS=' + ($fw -join ','))
  Write-Output ('SYSVOL=' + (Test-Path '\\localhost\SYSVOL'))
  Write-Output ('ADDS=' + (Get-WindowsFeature AD-Domain-Services).Installed)
} -ErrorAction Continue | Write-Output
