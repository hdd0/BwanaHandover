Write-Host '--- services referencing local-search / 3369 ---'
Get-CimInstance Win32_Service | Where-Object { $_.PathName -match 'local-search|3369' } | Select-Object Name, State, StartMode, PathName | Format-List
Write-Host '--- scheduled tasks referencing local-search / 3369 ---'
Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object { $t=$_; $a = ($t.Actions | ForEach-Object { $_.Execute + ' ' + $_.Arguments }) -join ' | '; if ($a -match 'local-search|3369') { "$($t.TaskName) :: $a" } }
Write-Host '--- ancestry of pid 48728 ---'
$p = 48728
for ($i=0; $i -lt 4; $i++) { $c = Get-CimInstance Win32_Process -Filter "ProcessId=$p" -ErrorAction SilentlyContinue; if (-not $c) { break }; "pid=$p name=$($c.Name) parent=$($c.ParentProcessId) cmd=$($c.CommandLine)"; $p = $c.ParentProcessId }
