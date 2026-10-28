$ports = 3366, 3369, 1337, 11434, 1234
foreach ($p in $ports) {
  $hits = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue
  if (-not $hits) { "port $p : NOT LISTENING"; continue }
  foreach ($h in $hits | Select-Object -Unique OwningProcess) {
    $c = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $h.OwningProcess)
    "port $p : pid=$($h.OwningProcess) cmd=$($c.CommandLine)"
  }
}
