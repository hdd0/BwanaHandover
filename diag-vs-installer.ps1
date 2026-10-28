$ErrorActionPreference = 'Continue'

Write-Output '=== SETUP PROCESSES ==='
Get-Process -Name setup -ErrorAction SilentlyContinue |
    Select-Object Id, ProcessName, StartTime, MainWindowTitle, SessionId |
    Format-Table -AutoSize | Out-String -Width 200

Write-Output '=== SETUP PROCESS COMMAND LINES ==='
Get-CimInstance Win32_Process -Filter "Name='setup.exe'" |
    Select-Object ProcessId, ParentProcessId, CommandLine |
    Format-List | Out-String -Width 400

Write-Output '=== dd_installer_20261017154629.log (winget passive run) ==='
Get-Content 'C:\Users\howar\AppData\Local\Temp\dd_installer_20261017154629.log' -ErrorAction SilentlyContinue |
    Select-Object -Last 40 | Out-String -Width 300

Write-Output '=== dd_bootstrapper_20261017154621.log (last 30) ==='
Get-Content 'C:\Users\howar\AppData\Local\Temp\dd_bootstrapper_20261017154621.log' -ErrorAction SilentlyContinue |
    Select-Object -Last 30 | Out-String -Width 300

Write-Output '=== dd_setup_20261017153713.log TAIL (interactive 15:37 run) ==='
Get-Content 'C:\Users\howar\AppData\Local\Temp\dd_setup_20261017153713.log' -ErrorAction SilentlyContinue |
    Select-Object -Last 45 | Out-String -Width 300

Write-Output '=== PRE-CHECK / KEYBOX HITS ==='
Select-String -Path 'C:\Users\howar\AppData\Local\Temp\dd_setup_20261017153713.log' `
    -Pattern 'pre-check|precheck|keybox|blocked|not supported|out of support|Warning|Error' `
    -ErrorAction SilentlyContinue |
    Select-Object -Last 25 | ForEach-Object { "$($_.LineNumber): $($_.Line)" } | Out-String -Width 300