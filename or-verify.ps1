$p = Get-Process -Id 38548 -ErrorAction SilentlyContinue
if ($p -and $p.ProcessName -eq 'node') { Stop-Process -Id 38548 -Force; Write-Output "stopped old gateway pid 38548" }
Start-Sleep 2
Start-Process node -ArgumentList "gateway.mjs" -WorkingDirectory "C:\STEP\step-ai-gateway" -WindowStyle Hidden
Start-Sleep 3
$prov = Invoke-RestMethod http://127.0.0.1:3367/api/providers
Write-Output "--- providers ---"
$prov | ConvertTo-Json -Depth 4
Write-Output "--- direct chat via 3367 (openrouter) ---"
$body = @{ q = "Reply with exactly: OPENROUTER OK"; provider = "openrouter" } | ConvertTo-Json
try { $r = Invoke-RestMethod -Uri http://127.0.0.1:3367/api/chat -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 130; $r | ConvertTo-Json -Depth 4 } catch { Write-Output "ERR: $($_.Exception.Message)"; try { $_.ErrorDetails.Message } catch {} }
Write-Output "--- via 3366 /ai route ---"
try { $r2 = Invoke-RestMethod -Uri http://127.0.0.1:3366/ai/api/chat -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 130; $r2 | ConvertTo-Json -Depth 4 } catch { Write-Output "ERR: $($_.Exception.Message)" }
