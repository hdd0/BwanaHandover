$ErrorActionPreference = 'Stop'
$exe = 'C:\Program Files\Microsoft VS Code\Code.exe'
$task = 'VSCode-Elevated'
$me = "$env:USERDOMAIN\$env:USERNAME"
$existing = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
if (-not $existing) {
  $act = New-ScheduledTaskAction -Execute $exe
  $pri = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Highest
  $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
  Register-ScheduledTask -TaskName $task -Action $act -Principal $pri -Settings $set `
    -Description 'Launch VS Code elevated without UAC prompt (manual shortcut only)' | Out-Null
  Write-Output 'METHOD3-CREATED: scheduled task VSCode-Elevated (Highest, on-demand only)'
} else { Write-Output 'METHOD3-OK: task already exists' }
# No-UAC desktop shortcut -> schtasks /run
$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'VS Code (No UAC).lnk'
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = "$env:SystemRoot\System32\schtasks.exe"
$sc.Arguments = "/run /tn `"\$task`""
$sc.WorkingDirectory = 'C:\Program Files\Microsoft VS Code'
$sc.IconLocation = "$exe,0"
$sc.Description = 'VS Code elevated, no UAC prompt (via scheduled task)'
$sc.Save()
Write-Output 'METHOD3-OK: desktop shortcut VS Code (No UAC).lnk created'
Get-ScheduledTask -TaskName $task | Format-Table TaskName, State -AutoSize
