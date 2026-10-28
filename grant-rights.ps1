$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $plain -AsPlainText -Force))

$body = @'
param($Acct, $Plain)
$u = 'BwanaBackupSvc'
$fqdn = $env:COMPUTERNAME + '\' + $u

# 1. Ensure membership of Backup Operators (use the FQ form)
try {
  $members = (Get-LocalGroupMember -Group 'Backup Operators' -EA SilentlyContinue).Name
  if ($members -notcontains $fqdn) { Add-LocalGroupMember -Group 'Backup Operators' -Member $fqdn -EA Stop; Write-Output 'BACKUP-OPS-ADDED' }
  else { Write-Output 'BACKUP-OPS-OK' }
} catch { Write-Output ('BACKUP-OPS-ERR: ' + $_.Exception.Message) }
Write-Output ('InBackupOperators=' + (((Get-LocalGroupMember -Group 'Backup Operators' -EA SilentlyContinue).Name) -contains $fqdn))

# 2. Grant "Log on as a batch job" (SeBatchLogonRight) via secedit
$tmp = Join-Path $env:TEMP 'sec-t.inf'
$tmp2 = Join-Path $env:TEMP 'sec-t2.inf'
& secedit.exe /export /cfg $tmp /areas SECURITYPOLICY | Out-Null
$lines = Get-Content $tmp
$inSec = $false
$out = @()
foreach ($l in $lines) {
  if ($l -match '^\[Privilege Rights\]') { $inSec = $true; $out += $l; continue }
  if ($inSec -and $l -match '^\[') { $inSec = $false }
  if ($inSec -and $l -match '^SeBatchLogonRight\s*=') {
    $val = ($l -split '=',2)[1].Trim()
    $entries = @($val -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($entries -notcontains '*S-1-5-32-551') { $entries += '*S-1-5-32-551' }
    $out += ('SeBatchLogonRight = ' + ($entries -join ','))
    Write-Output 'BATCHLOGON-GRANTED'
  } else { $out += $l }
}
Set-Content -Path $tmp2 -Value $out -Encoding Unicode
& secedit.exe /configure /db $tmp2 /areas SECURITYPOLICY | Out-Null
Write-Output ('SECEDIT-RC=' + $LASTEXITCODE)
'@

$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $P)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\grant-rights.ps1' $t -Force
    & 'C:\grant-rights.ps1' -Acct 'BwanaBackupSvc' -Plain $P
  } -ArgumentList $b64, $plain -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
