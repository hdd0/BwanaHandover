$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$target = '\\192.168.150.1\BwanaBackups\BWANA-DC01\SystemState'
New-Item -ItemType Directory -Force -Path $target | Out-Null
$argStr = 'start backup -backupTarget:"' + $target + '" -include:SystemState -allCritical'
$p = Start-Process wbadmin.exe -ArgumentList $argStr -Wait -NoNewWindow -PassThru -RedirectStandardOutput 'C:\wbo.txt' -RedirectStandardError 'C:\wbe.txt'
Write-Output ('exit=' + $p.ExitCode)
Write-Output '=== FULL STDOUT ==='
Get-Content 'C:\wbo.txt' -EA SilentlyContinue | ForEach-Object { Write-Output $_ }
Write-Output '=== FULL STDERR ==='
Get-Content 'C:\wbe.txt' -EA SilentlyContinue | ForEach-Object { Write-Output $_ }
Write-Output '=== VSS writers ==='
& vssadmin.exe list writers 2>&1 | Select-String -Pattern 'NTDS|State:|Last error' | Select-Object -First 12 | ForEach-Object { Write-Output $_ }
Write-Output '=== share perms seen by DC ==='
& cmd.exe /c 'net view \\192.168.150.1\BwanaBackups' 2>&1 | ForEach-Object { Write-Output $_ }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag6.ps1' $t -Force
  & 'C:\diag6.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
