$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)

$body = @'
param($Target, $User, $Pass)
& cmdkey.exe /delete:192.168.150.1 2>$null | Out-Null
& cmdkey.exe /add:192.168.150.1 /user:$User /pass:$Pass | Out-Null
Write-Output 'CREDSTORED'
$root = '\\192.168.150.1\BwanaBackups'
try {
  $f = $root + '\probe-' + $env:COMPUTERNAME + '.txt'
  Set-Content -Path $f -Value ('probe ' + (Get-Date -Format s)) -Force -ErrorAction Stop
  Write-Output ('SHARE-WRITE-OK: ' + (Get-Content $f))
  Remove-Item $f -Force -ErrorAction SilentlyContinue
} catch { Write-Output ('SHARE-ERR: ' + $_.Exception.Message) }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('--- ' + $vm + ' ---')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $T, $U, $P)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\probe5.ps1' $t -Force
    & 'C:\probe5.ps1' -Target $T -User $U -Pass $P
  } -ArgumentList $b64, '192.168.150.1', 'BwanaBackupSvc', $plain -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
