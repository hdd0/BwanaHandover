$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Write-Output '--- WinRM over network to DC02 ---'
try {
  $r = Invoke-Command -ComputerName '192.168.150.11' -Credential $cred -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
  Write-Output ('WINRM-OK host=' + $r)
} catch { Write-Output ('WINRM-FAIL: ' + $_.Exception.Message) }
Write-Output '--- DNS view of DC02 from DC01 ---'
try {
  Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    try { 'A=' + ((Resolve-DnsName 'BWANA-DC02.ad.bwanakhasu.one' -EA Stop | Where-Object { $_.IPAddress } | Select-Object -First 1).IPAddress) } catch { 'A-FAIL: ' + $_.Exception.Message }
    try { 'SRV=' + ((Resolve-DnsName '_ldap._tcp.dc._msdcs.ad.bwanakhasu.one' SRV -EA Stop | Select-Object -ExpandProperty NameTarget) -join ',') } catch { 'SRV-FAIL' }
    try { 'NTDSVC-DC02(via RPC)=' + (Get-Service -ComputerName 'BWANA-DC02' -Name NTDS -EA Stop).Status } catch { 'RPC-FAIL: ' + $_.Exception.Message }
  } -ErrorAction Stop | Write-Output
} catch { Write-Output ('DC01-QUERY-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
