$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
Write-Output '=== WSB feature ==='
Write-Output ('WSB-installed=' + (Get-WindowsFeature Windows-Server-Backup).Installed)
Write-Output '=== wbadmin attempt (verbose) ==='
$ss = 'C:\BwanaBackupStage\SystemState2'
New-Item -ItemType Directory -Force -Path $ss | Out-Null
& wbadmin.exe start backup -backupTarget:"$ss" -include:SystemState -allCritical -verbose 2>&1 | Select-Object -Last 30 | ForEach-Object { Write-Output $_ }
Write-Output '=== IFM attempt (ntdsutil) ==='
$ifm = 'C:\IFM-TEST'
if (Test-Path $ifm) { Remove-Item $ifm -Recurse -Force -ErrorAction SilentlyContinue }
$cmdfile = 'C:\ifm-cmds.txt'
@(
  'activate instances ntds'
  'ifm'
  'create full C:\IFM-TEST /h'
  'quit'
  'quit'
) | Set-Content $cmdfile -Encoding ASCII
& ntdsutil.exe /h (Join-Path $env:SystemRoot 'System32') 2>&1 | Out-Null
cmd.exe /c "ntdsutil.exe < C:\ifm-cmds.txt" 2>&1 | ForEach-Object { Write-Output $_ }
Write-Output ('IFM-EXISTS=' + (Test-Path (Join-Path $ifm 'NTDS.dit')))
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag-backup.ps1' $t -Force
  & 'C:\diag-backup.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
