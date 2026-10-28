Write-Host "=== Direct probes ==="
$ports = @(11434, 1234, 1337, 18789)
foreach ($p in $ports) {
  $url = "http://127.0.0.1:$p/api/tags"
  try {
    $r = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 15
    "port $p -> HTTP $($r.StatusCode) len $($r.RawContentLength)"
  } catch {
    "port $p -> DOWN ($($_.Exception.Message.Split("`n")[0]))"
  }
}
