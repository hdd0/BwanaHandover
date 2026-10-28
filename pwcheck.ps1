$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
Write-Output ('pwfile exists: ' + (Test-Path 'C:\BwanaSharePw.txt'))
$raw = Get-Content 'C:\BwanaSharePw.txt' -Raw
Write-Output ('pwfile length: ' + $raw.Length)
try {
  $pw = ($raw).Trim() | ConvertTo-SecureString
  $p = $pw.GetNetworkCredential().Password
  Write-Output ('recovered length: ' + $p.Length)
} catch { Write-Output ('RECOVER-ERR: ' + $_.Exception.Message) }
Write-Output '--- direct net use with recovered pw ---'
try {
  $s = ($raw).Trim() | ConvertTo-SecureString
  $c = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', $s)
  $plain = $c.GetNetworkCredential().Password
  Write-Output ('plain length: ' + $plain.Length)
  & net.exe use BK: /delete /y 2>&1 | Out-Null
  & net.exe use * /delete /y 2>&1 | Out-Null
  $out = & net.exe use BK: '\\192.168.150.1\BwanaBackups' $plain '/user:192.168.150.1\BwanaBackupSvc' /persistent:no 2>&1
  $out | ForEach-Object { Write-Output ('  ' + $_) }
  Write-Output ('net use rc=' + $LASTEXITCODE)
  Write-Output ('BK exists: ' + (Test-Path 'BK:\'))
  & cmd.exe /c "dir BK:\" 2>&1 | Select-Object -First 8 | ForEach-Object { Write-Output ('  ' + $_) }
} catch { Write-Output ('ERR: ' + $_.Exception.Message) }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\pwcheck.ps1' $t -Force
  & 'C:\pwcheck.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
