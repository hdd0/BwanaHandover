$ErrorActionPreference = "Stop"
$pid3366 = 13916
try { Stop-Process -Id $pid3366 -Force; Write-Output ("STOPPED " + $pid3366) } catch { Write-Output ("STOP_FAIL " + $pid3366 + " " + $_.Exception.Message) }
Start-Sleep -Seconds 2
$node = "C:\Program Files\nodejs\node.exe"
Start-Process -FilePath $node -ArgumentList "server.js" -WorkingDirectory "C:\STEP\gateway-3366" -WindowStyle Hidden
Write-Output "STARTED new gateway, waiting for health..."
$ok = $false
for ($i = 0; $i -lt 10; $i++) {
  Start-Sleep -Seconds 1
  try {
    $h = Invoke-WebRequest -Uri "http://127.0.0.1:3366/health" -UseBasicParsing -TimeoutSec 3
    if ($h.StatusCode -eq 200) { Write-Output ("HEALTH_OK attempt=" + $i + " " + $h.Content); $ok = $true; break }
  } catch { Write-Output ("health attempt " + $i + " not ready yet") }
}
if (-not $ok) { Write-Output "HEALTH_FAILED"; exit 1 }
