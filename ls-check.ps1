Get-NetTCPConnection -State Listen -LocalPort 3369 | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
$c = Get-CimInstance Win32_Process -Filter 'ProcessId=48728'
"parent=$($c.ParentProcessId) cwd-cmd=$($c.CommandLine)"
(Get-Process -Id $c.ParentProcessId -ErrorAction SilentlyContinue).ProcessName
Select-String -Path 'C:\STEP\local-search\server.js' -Pattern 'listen|createServer|url.pathname|pathname ===|pathname.startsWith' | Select-Object -First 25 | ForEach-Object { "{0}:{1}" -f $_.LineNumber, $_.Line }
