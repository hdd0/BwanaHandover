foreach ($port in @(3300, 3100, 3366, 3367, 3368, 4000, 5173, 7070, 18789)) {
  try {
    $resp = Invoke-WebRequest -Uri ('http://127.0.0.1:' + $port + '/') -TimeoutSec 5 -UseBasicParsing
    $title = ''
    if ($resp.Content -match '<title>(.*?)</title>') { $title = $matches[1] }
    $snippet = $resp.Content.Substring(0, [Math]::Min(160, $resp.Content.Length)) -replace '\s+', ' '
    Write-Host ('PORT ' + $port + ' [' + $resp.StatusCode + '] title="' + $title + '" :: ' + $snippet)
  } catch {
    Write-Host ('PORT ' + $port + ' ERR: ' + $_.Exception.Message)
  }
}
Write-Host 'PROBE-DONE'
