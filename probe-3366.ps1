$base = "http://127.0.0.1:3366"
try {
  $h = Invoke-WebRequest -Uri ($base + "/health") -UseBasicParsing -TimeoutSec 5
  Write-Output ("HEALTH=" + $h.StatusCode + " " + $h.Content)
} catch { Write-Output ("HEALTH_ERR=" + $_.Exception.Message) }
foreach ($ep in @("start","status","qa","log")) {
  try {
    $body = (@{ deploymentId = "PROBE-TEST"; stage = "probe"; status = "PASS"; message = "probe"; timestamp = "2026-09-29" } | ConvertTo-Json -Compress)
    $r = Invoke-RestMethod -Uri ($base + "/api/deployments/" + $ep) -Method Post -Body $body -ContentType "application/json" -TimeoutSec 8
    Write-Output ("POST_" + $ep + "=200 ok=" + $r.ok)
  } catch {
    $msg = $_.Exception.Message
    if ($_.Exception.Response) { $msg = "HTTP " + [int]$_.Exception.Response.StatusCode + " " + $_.Exception.Response.StatusCode }
    Write-Output ("POST_" + $ep + "_ERR=" + $msg)
  }
}
