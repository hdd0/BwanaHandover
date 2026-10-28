Write-Host "=== parent powershell of node (pid 44500) ==="
Get-CimInstance Win32_Process -Filter 'ProcessId=44500' | Select-Object ProcessId, Name, CommandLine | Format-List

Write-Host "=== C:\STEP top level ==="
Get-ChildItem 'C:\STEP' -Directory | Select-Object Name, LastWriteTime | Sort-Object Name | Format-Table -Auto

Write-Host "=== all node processes with 'server' or 'serve' in cmdline ==="
Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Select-Object ProcessId, CommandLine | Format-Table -Auto -Wrap
