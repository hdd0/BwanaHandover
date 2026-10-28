Write-Output "--- listeners 3367 ---"
Get-NetTCPConnection -LocalPort 3367 -State Listen -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
Write-Output "--- 3366 /ai forwarding ---"
Select-String -Path "C:\STEP\gateway-3366\server.js" -Pattern "'/ai|3367|/api/chat" | Select-Object -First 15 | ForEach-Object { "$($_.LineNumber): $($_.Line.Trim().Substring(0,[Math]::Min(220,$_.Line.Trim().Length)))" }
Write-Output "--- .env.local tail bytes ---"
(Get-Content "C:\STEP\step-ai-gateway\.env.local" -Raw).Length
