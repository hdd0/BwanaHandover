$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
Write-Output '=== IFM via Start-Process stdin redirect ==='
$ifm = 'C:\IFM-WORK'
if (Test-Path $ifm) { Remove-Item $ifm -Recurse -Force -ErrorAction SilentlyContinue }
$cmdfile = 'C:\ifm-work.txt'
$lines = @('activate instances ntds','ifm','create full ' + $ifm,'quit','quit')
[IO.File]::WriteAllText($cmdfile, ($lines -join "`r`n"))
$outFile = 'C:\ifm-out.txt'
$errFile = 'C:\ifm-err.txt'
$p = Start-Process -FilePath "$env:SystemRoot\System32\ntdsutil.exe" -RedirectStandardInput $cmdfile -RedirectStandardOutput $outFile -RedirectStandardError $errFile -NoNewWindow -Wait -PassThru
Write-Output ('exitcode=' + $p.ExitCode)
Get-Content $outFile -ErrorAction SilentlyContinue | ForEach-Object { if ($_ -match '\S') { Write-Output $_ } }
Get-Content $errFile -ErrorAction SilentlyContinue | ForEach-Object { if ($_ -match '\S') { Write-Output ('ERR: ' + $_) } }
Write-Output ('IFM-EXISTS=' + (Test-Path (Join-Path $ifm 'NTDS.dit')))

Write-Output '=== WSB direct to UNC share ==='
$target = '\\192.168.150.1\BwanaBackups\BWANA-DC01\SystemState'
New-Item -ItemType Directory -Force -Path $target | Out-Null
$args = @('start','backup','-backupTarget:' + $target,'-include:SystemState','-allCritical')
& wbadmin.exe @args 2>&1 | Select-Object -Last 12 | ForEach-Object { Write-Output $_ }
Write-Output ('WB-FILES=' + (Get-ChildItem $target -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count)
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag3.ps1' $t -Force
  & 'C:\diag3.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
