$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
Write-Output '=== IFM fixed ==='
$ifm = 'C:\IFM-OK'
if (Test-Path $ifm) { Remove-Item $ifm -Recurse -Force -ErrorAction SilentlyContinue }
$f = 'C:\ifm-ok.txt'
[IO.File]::WriteAllText($f, ("activate instance ntds`r`nifm`r`ncreate full $ifm`r`nquit`r`nquit"), [Text.Encoding]::ASCII)
$of='C:\ifm-oko.txt'; $ef='C:\ifm-oke.txt'
$p = Start-Process "$env:SystemRoot\System32\ntdsutil.exe" -RedirectStandardInput $f -RedirectStandardOutput $of -RedirectStandardError $ef -NoNewWindow -Wait -PassThru
Get-Content $of -EA SilentlyContinue | ForEach-Object { if ($_ -match '\S') { Write-Output ('  out: ' + $_) } }
Get-Content $ef -EA SilentlyContinue | ForEach-Object { if ($_ -match '\S') { Write-Output ('  err: ' + $_) } }
Write-Output ('IFM-EXISTS=' + (Test-Path (Join-Path $ifm 'NTDS.dit')))
Write-Output ('IFM-SIZE=' + ((Get-ChildItem $ifm -Recurse -File -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum))

Write-Output '=== WSB fixed via Start-Process ArgumentList ==='
$target = '\\192.168.150.1\BwanaBackups\BWANA-DC01\SystemState'
New-Item -ItemType Directory -Force -Path $target | Out-Null
$argstr = 'start backup -backupTarget:"' + $target + '" -include:SystemState -allCritical'
Write-Output ('ARGSTR=' + $argstr)
$wout = & Start-Process wbadmin.exe -ArgumentList $argstr -Wait -NoNewWindow -PassThru -RedirectStandardOutput 'C:\wb-o.txt' -RedirectStandardError 'C:\wb-e.txt'
Get-Content 'C:\wb-o.txt' -EA SilentlyContinue | Select-Object -First 10 | ForEach-Object { if ($_ -match '\S') { Write-Output ('  out: ' + $_) } }
Get-Content 'C:\wb-e.txt' -EA SilentlyContinue | Select-Object -First 10 | ForEach-Object { if ($_ -match '\S') { Write-Output ('  err: ' + $_) } }
Write-Output ('WB-FILES=' + (Get-ChildItem $target -Recurse -File -EA SilentlyContinue | Measure-Object).Count)
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag5.ps1' $t -Force
  & 'C:\diag5.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
