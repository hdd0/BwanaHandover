$ports = 3369, 1337, 3367, 3368
$l = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
foreach ($p in $ports) {
  $hit = $l | Where-Object { $_.LocalPort -eq $p } | Select-Object -First 1
  if ($hit) {
    $proc = (Get-Process -Id $hit.OwningProcess -ErrorAction SilentlyContinue).ProcessName
    $cmd = (Get-CimInstance Win32_Process -Filter ("ProcessId=" + $hit.OwningProcess) -ErrorAction SilentlyContinue).CommandLine
    "port {0,-6} LISTEN pid={1,-7} proc={2,-8} cmd={3}" -f $p, $hit.OwningProcess, $proc, $cmd
  } else { "port {0,-6} free" -f $p }
}
Write-Host "--- probes ---"
foreach ($u in @('http://127.0.0.1:3369/','http://127.0.0.1:1337/v1/models','http://127.0.0.1:3367/')) {
  try { $r = Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 4 -ErrorAction Stop; "{0,-40} HTTP {1}" -f $u, $r.StatusCode }
  catch { "{0,-40} DOWN ({1})" -f $u, $_.Exception.Message.Split("`n")[0] }
}
