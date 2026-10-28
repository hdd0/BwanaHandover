$envFile = "C:\STEP\step-ai-gateway\.env.local"
$lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^\s*OPENROUTER_MODEL=' })
$lines += "OPENROUTER_MODEL=openrouter/free"
Set-Content -Path $envFile -Value $lines -Encoding UTF8
$gw = Get-NetTCPConnection -LocalPort 3367 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($gw) { Stop-Process -Id $gw.OwningProcess -Force; Write-Output "stopped gateway pid $($gw.OwningProcess)" }
Start-Sleep 2
Start-Process node -ArgumentList "gateway.mjs" -WorkingDirectory "C:\STEP\step-ai-gateway" -WindowStyle Hidden
Start-Sleep 3
$body = @{ q = "Reply with exactly: FREE OK"; provider = "openrouter" } | ConvertTo-Json
Write-Output "--- A: default (openrouter/free) via 3367 ---"
try { Invoke-RestMethod -Uri http://127.0.0.1:3367/api/chat -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 130 | ConvertTo-Json -Depth 4 } catch { Write-Output "HTTP error: $($_.Exception.Message)"; $_.ErrorDetails.Message }
$paid = @{ q = "hi"; provider = "openrouter"; model = "openai/gpt-4o" } | ConvertTo-Json
Write-Output "--- B: paid model must be blocked ---"
try { Invoke-RestMethod -Uri http://127.0.0.1:3367/api/chat -Method Post -ContentType 'application/json' -Body $paid -TimeoutSec 60 | ConvertTo-Json -Depth 4 } catch { Write-Output "HTTP error: $($_.Exception.Message)"; $_.ErrorDetails.Message }
