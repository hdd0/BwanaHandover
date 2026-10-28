$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  try {
    Set-DnsServerForwarder -IPAddress @('1.1.1.1','8.8.8.8') -ErrorAction Stop
    'FORWARDERS-SET'
  } catch { 'FWD-ERR: ' + $_.Exception.Message }
  'NOW=' + ((Get-DnsServerForwarder -ErrorAction SilentlyContinue).IPAddressToString -join ',')
} -ErrorAction Continue | Write-Output
