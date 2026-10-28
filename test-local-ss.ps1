$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bk64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw)))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
  Write-Output 'SCRIPT-UPDATED'
  Write-Output '--- dry run: wbadmin to local mount point ---'
  New-Item -ItemType Directory -Force -Path 'C:\BwanaSystemState' | Out-Null
  $argStr = 'start backup -backupTarget:"C:\BwanaSystemState\" -allCritical -quiet'
  Write-Output ('ARG=' + $argStr)
  $p = Start-Process wbadmin.exe -ArgumentList $argStr -NoNewWindow -PassThru -RedirectStandardOutput 'C:\wbt.txt' -RedirectStandardError 'C:\wbte.txt'
  if (-not $p.WaitForExit(1500000)) { Write-Output 'TIMEOUT'; try { $p.Kill() } catch {} }
  else {
    Write-Output ('exit=' + $p.ExitCode)
    Get-Content 'C:\wbt.txt' -EA SilentlyContinue | Select-Object -First 8 | ForEach-Object { Write-Output $_ }
  }
  Write-Output ('files=' + (Get-ChildItem 'C:\BwanaSystemState' -Recurse -File -EA SilentlyContinue | Measure-Object).Count)
} -ArgumentList $bk64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
