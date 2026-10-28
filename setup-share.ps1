$ErrorActionPreference = 'Continue'
$root = 'C:\BwanaBackups'
New-Item -ItemType Directory -Force -Path $root | Out-Null
$share = 'BwanaBackups'
if (-not (Get-SmbShare -Name $share -ErrorAction SilentlyContinue)) {
  New-SmbShare -Name $share -Path $root -FullAccess 'BWDOMAIN\Domain Admins','BWDOMAIN\Bwana-Admins','NT AUTHORITY\SYSTEM' -Description 'Bwana AD backup target' | Out-Null
  Write-Output 'SHARE-CREATED'
} else { Write-Output 'SHARE-EXISTS' }
# Allow SMB/file sharing on the VLAN 150 interface for the DC subnet
try {
  $rule = Get-NetFirewallRule -DisplayName 'Bwana Backup SMB (445)' -ErrorAction SilentlyContinue
  if (-not $rule) {
    New-NetFirewallRule -DisplayName 'Bwana Backup SMB (445)' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 445 -RemoteAddress 192.168.150.0/24 -Profile Any | Out-Null
    Write-Output 'FW-RULE-CREATED'
  } else { Write-Output 'FW-RULE-EXISTS' }
} catch { Write-Output ('FW-ERR: ' + $_.Exception.Message) }
Get-SmbShare -Name $share | Select-Object Name, Path | Format-Table -AutoSize | Out-String | Write-Output
Write-Output ('HOST-IP=' + ((Get-NetIPAddress -IPAddress '192.168.150.1').IPAddress))
Write-Output 'DONE'
