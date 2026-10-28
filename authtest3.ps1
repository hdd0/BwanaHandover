$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
param($Plain)
$ErrorActionPreference = 'Continue'
$root = '\\192.168.150.1\BwanaBackups'
# clean slate: drop every session to that server first
& net.exe use \\192.168.150.1 /delete /y 2>&1 | Out-Null
& net.exe use * /delete /y 2>&1 | Out-Null
Start-Sleep -Seconds 3
Write-Output '--- net use after cleanup ---'
& net.exe use 2>&1 | ForEach-Object { Write-Output ('  ' + $_) }
foreach ($u in @('192.168.150.1\BwanaBackupSvc', 'BwanaBackupSvc')) {
  $c = New-Object System.Management.Automation.PSCredential($u, (ConvertTo-SecureString $Plain -AsPlainText -Force))
  Write-Output ('--- try ' + $u)
  try {
    New-PSDrive -Name T9 -PSProvider FileSystem -Root $root -Credential $c -Scope Script -EA Stop | Out-Null
    Write-Output '  MAP-OK'
    robocopy $root 'C:\probe-out' /E /R:1 /W:3 /NFL /NDL /NP 2>&1 | Select-Object -Last 3 | ForEach-Object { Write-Output ('  robocopy: ' + $_) }
    Write-Output ('  robocopy-rc=' + $LASTEXITCODE)
    Remove-PSDrive T9 -Force -EA SilentlyContinue
  } catch { Write-Output ('  FAIL: ' + $_.Exception.Message) }
}
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B, $P)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\authtest3.ps1' $t -Force
  & 'C:\authtest3.ps1' -Plain $P
} -ArgumentList $b64, $plain -ErrorAction Continue | Write-Output
Write-Output 'DONE'
