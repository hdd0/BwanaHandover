$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('192.168.150.1\BwanaBackupSvc', $bsec)
$body = @'
param($Root, $HostCred)
$drv = 'BK'
try {
  New-PSDrive -Name $drv -PSProvider FileSystem -Root $Root -Credential $HostCred -Scope Global -ErrorAction Stop | Out-Null
  $f = Join-Path ($drv + ':') ('probe-' + $env:COMPUTERNAME + '.txt')
  Set-Content -Path $f -Value ('probe ' + (Get-Date -Format s)) -Force -ErrorAction Stop
  Write-Output ('SHARE-WRITE-OK: ' + (Get-Content $f))
} catch { Write-Output ('SHARE-ERR: ' + $_.Exception.Message) }
try { Remove-PSDrive -Name $drv -Force -ErrorAction SilentlyContinue } catch {}
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
$root = '\\192.168.150.1\BwanaBackups'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('--- ' + $vm + ' ---')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $R, $HC)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\probe4.ps1' $t -Force
    & 'C:\probe4.ps1' -Root $R -HostCred $HC
  } -ArgumentList $b64, $root, $bcred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
