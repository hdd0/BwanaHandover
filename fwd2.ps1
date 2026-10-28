$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Start-Sleep -Seconds 120
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- forwarder set attempt ---'
  try {
    Set-DnsServerForwarder -IPAddress @('1.1.1.1','8.8.8.8') -Force -ErrorAction Stop
    Write-Output 'SET-OK'
  } catch { Write-Output ('SET-ERR: ' + $_.Exception.Message) }
  Write-Output '--- read back ---'
  $f = Get-DnsServerForwarder -ErrorAction SilentlyContinue
  if ($f) { $f | Format-List * | Out-String | Write-Output } else { Write-Output 'NULL-RESULT' }
  Write-Output '--- external resolution test ---'
  try { $r = Resolve-DnsName 'www.microsoft.com' -ErrorAction Stop; Write-Output ('RESOLVED=' + $r[0].IPAddress) }
  catch { Write-Output ('RESOLVE-ERR: ' + $_.Exception.Message) }
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
