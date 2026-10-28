$nodes = Get-Process node -ErrorAction SilentlyContinue
foreach ($p in $nodes) {
  $c = ""
  try { $c = (Get-CimInstance Win32_Process -Filter ("ProcessId=" + $p.Id) -ErrorAction SilentlyContinue).CommandLine } catch {}
  Write-Output ("PID=" + $p.Id + " start=" + $p.StartTime + " :: " + $c)
}
