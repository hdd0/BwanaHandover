$conns = Get-NetTCPConnection -State Listen | Where-Object {$_.LocalPort -ge 3000 -and $_.LocalPort -le 5000}
$pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
$procs = @{}
foreach($p in $pids){ $procs[$p] = (Get-CimInstance Win32_Process -Filter "ProcessId=$p").CommandLine }
$conns | ForEach-Object { [PSCustomObject]@{ Port=$_.LocalPort; Addr=$_.LocalAddress; PID=$_.OwningProcess; Cmd=($procs[$_.OwningProcess] -replace '\s+',' ')} } | Sort-Object Port -Unique | Format-Table -AutoSize -Wrap
