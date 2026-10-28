$proc = Get-CimInstance Win32_Process -Filter 'ProcessId=12748'
"PID={0}  ParentPID={1}" -f $proc.ProcessId, $proc.ParentProcessId
$proc | Format-List ExecutablePath, CommandLine

# parent chain
$pid = $proc.ProcessId
for ($i=0; $i -lt 4; $i++) {
  $p = Get-CimInstance Win32_Process -Filter ("ProcessId=" + $pid)
  if (-not $p) { break }
  "PARENT pid={0}  name={1}" -f $p.ProcessId, $p.Name
  $pid = $p.ParentProcessId
}
