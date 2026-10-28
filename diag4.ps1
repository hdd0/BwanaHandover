$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
Write-Output '=== wbadmin FULL output ==='
$target = '\\192.168.150.1\BwanaBackups\BWANA-DC01\SystemState'
$args = @('start','backup','-backupTarget:' + $target,'-include:SystemState','-allCritical')
$o = & wbadmin.exe @args 2>&1
$i = 0
foreach ($line in $o) { if ($i -lt 12) { Write-Output ('L' + $i + ': ' + $line) }; $i++ }
Write-Output ('TOTAL-LINES=' + $i)
Write-Output '--- wsbadmin list ---'
& wbadmin.exe get versions 2>&1 | ForEach-Object { Write-Output $_ }
Write-Output '=== ntdsutil single-command tests (ASCII) ==='
foreach ($cmd in @('activate instances ntds', 'activate instance ntds')) {
  $f = 'C:\n1.txt'
  [IO.File]::WriteAllText($f, $cmd, [Text.Encoding]::ASCII)
  $of = 'C:\n1o.txt'; $ef = 'C:\n1e.txt'
  $p = Start-Process "$env:SystemRoot\System32\ntdsutil.exe" -RedirectStandardInput $f -RedirectStandardOutput $of -RedirectStandardError $ef -NoNewWindow -Wait -PassThru
  Write-Output ("[$cmd] exit=" + $p.ExitCode)
  Get-Content $of -EA SilentlyContinue | ForEach-Object { if ($_ -match '\S') { Write-Output ('  out: ' + $_) } }
  Get-Content $ef -EA SilentlyContinue | ForEach-Object { if ($_ -match '\S') { Write-Output ('  err: ' + $_) } }
}
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag4.ps1' $t -Force
  & 'C:\diag4.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
