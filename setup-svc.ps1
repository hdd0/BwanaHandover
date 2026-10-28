$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $plain -AsPlainText -Force))
Write-Output ('plaintext length=' + $plain.Length + ' (sanity: non-empty)')

$body = @'
param($Plain)
$ErrorActionPreference = 'Continue'
$u = 'BwanaBackupSvc'
$sec = ConvertTo-SecureString $Plain -AsPlainText -Force

# 1) password
$existing = Get-LocalUser -Name $u -EA SilentlyContinue
if ($existing) { Set-LocalUser -Name $u -Password $sec -EA Stop; Write-Output 'PW-SET' }
else { New-LocalUser -Name $u -Password $sec -Description 'Bwana backup runner' -EA Stop | Out-Null; Write-Output 'PW-CREATED' }
$lu = Get-LocalUser -Name $u
Write-Output ('PasswordRequired=' + $lu.PasswordRequired)
& net.exe user $u /passwordchg:no /active:yes | Out-Null

# 2) Backup Operators via SID (name form is unreliable on a DC)
try {
  $sid = (Get-LocalUser -Name $u).SID
  $g = Get-LocalGroup -SID 'S-1-5-32-551'
  $g | Add-LocalGroupMember -Member $sid -ErrorAction Stop
  Write-Output 'BACKUPOPS-ADDED'
} catch { Write-Output ('BACKUPOPS-ERR: ' + $_.Exception.Message) }
$grpSids = @(Get-LocalGroupMember -Group 'Backup Operators' -EA SilentlyContinue | ForEach-Object { $_.SID.Value })
$userSid = (Get-LocalUser -Name $u).SID.Value
Write-Output ('InBackupOperators=' + ($grpSids -contains $userSid))

# 3) SeBatchLogonRight via secedit
try {
  $t1 = Join-Path $env:TEMP ('s1_' + [guid]::NewGuid().ToString('N') + '.inf')
  $t2 = Join-Path $env:TEMP ('s2_' + [guid]::NewGuid().ToString('N') + '.inf')
  & secedit.exe /export /cfg $t1 /areas SECURITYPOLICY | Out-Null
  $txt = Get-Content $t1 -Raw
  if ($txt -match '(?m)^SeBatchLogonRight\s*=\s*(.*)$') {
    $entries = @($Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $sidB = '*S-1-5-32-551'
    if ($entries -notcontains $sidB) {
      $entries += $sidB
      $txt = $txt -replace '(?m)^SeBatchLogonRight\s*=\s*.*$', ('SeBatchLogonRight = ' + ($entries -join ','))
      Set-Content -Path $t2 -Value $txt -Encoding Unicode
      $o = & secedit.exe /configure /db $t2 /areas SECURITYPOLICY 2>&1
      Write-Output ('SECEDIT: ' + ($o -join ' '))
    } else { Write-Output 'BATCHLOGON-ALREADY' }
  } else { Write-Output 'BATCHLOGON-KEY-NOT-FOUND' }
} catch { Write-Output ('SECEDIT-ERR: ' + $_.Exception.Message) }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $P)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\setup-svc.ps1' $t -Force
    & 'C:\setup-svc.ps1' -Plain $P
  } -ArgumentList $b64, $plain -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
