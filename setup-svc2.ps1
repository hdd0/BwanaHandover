$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
param($Plain)
$ErrorActionPreference = 'Continue'
$u = 'BwanaBackupSvc'

# 1) password, then PROVE it by SMB auth to the backup host
$s = ConvertTo-SecureString $Plain -AsPlainText -Force
Set-LocalUser -Name $u -Password $s -ErrorAction Stop
$wmi = Get-WmiObject Win32_UserAccount -Filter "Name='$u'"
$wmi.PasswordExpires = $false; $wmi.Put() | Out-Null
Write-Output 'PW-SET'
try {
  $c = New-Object System.Management.Automation.PSCredential($u, $s)
  New-PSDrive -Name VFY -PSProvider FileSystem -Root '\\192.168.150.1\BwanaBackups' -Credential $c -Scope Script -EA Stop | Out-Null
  Write-Output 'PASSWORD-PROVEN (SMB auth from DC succeeded)'
  Remove-PSDrive VFY -Force -EA SilentlyContinue
} catch { Write-Output ('PASSWORD-FAIL: ' + $_.Exception.Message) }

# 2) Backup Operators by name
try {
  Add-LocalGroupMember -Group 'Backup Operators' -Member $u -ErrorAction Stop
  Write-Output 'BACKUPOPS-ADDED'
} catch { Write-Output ('BACKUPOPS-ERR: ' + $_.Exception.Message) }
$memberSids = @(Get-LocalGroupMember -Group 'Backup Operators' -EA SilentlyContinue | ForEach-Object { $_.SID.Value })
Write-Output ('InBackupOperators=' + ($memberSids -contains (Get-LocalUser -Name $u).SID.Value))

# 3) SeBatchLogonRight - export the FULL policy so [Privilege Rights] is present
$id = [guid]::NewGuid().ToString('N')
$t1 = "C:\sec1_$id.inf"; $t2 = "C:\sec2_$id.inf"
& secedit.exe /export /cfg $t1 | Out-Null
Write-Output ('export-rc=' + $LASTEXITCODE)
$txt = Get-Content $t1 -Raw
$has = $txt -match '(?m)^SeBatchLogonRight\s*='
Write-Output ('key-present=' + $has)
if ($has) {
  $entries = @()
  if ($txt -match '(?m)^SeBatchLogonRight\s*=\s*(.*)$') { $entries = @($Matches[1] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
  if ($entries -notcontains '*S-1-5-32-551') {
    $entries += '*S-1-5-32-551'
    $txt = [regex]::Replace($txt, '(?m)^SeBatchLogonRight\s*=\s*.*$', ('SeBatchLogonRight = ' + ($entries -join ',')))
    Set-Content -Path $t2 -Value $txt -Encoding Unicode
    $o = & secedit.exe /configure /db $t2 /areas SECURITYPOLICY 2>&1
    Write-Output ('SECEDIT: ' + ($o -join ' '))
  } else { Write-Output 'BATCHLOGON-ALREADY' }
}
Remove-Item $t1, $t2 -Force -EA SilentlyContinue
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $P)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\setup-svc2.ps1' $t -Force
    & 'C:\setup-svc2.ps1' -Plain $P
  } -ArgumentList $b64, $plain -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
