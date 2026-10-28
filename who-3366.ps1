$health = try { (Invoke-WebRequest -Uri 'http://127.0.0.1:3366/health' -UseBasicParsing -TimeoutSec 5).Content } catch { $_.Exception.Message }
Write-Output "HEALTH=$health"
$p = Get-CimInstance Win32_Process -Filter 'ProcessId=731896'
Write-Output ("PARENT=" + $p.ParentProcessId)
$parent = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $p.ParentProcessId)
Write-Output ("PARENT_CMD=" + $parent.CommandLine)
Write-Output ("CMD=" + $p.CommandLine)
