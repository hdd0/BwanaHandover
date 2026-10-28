Get-Content "C:\STEP\step-ai-gateway\.gitignore"
Write-Output "--- git status step-ai-gateway ---"
git -C C:\STEP\step-ai-gateway status --short
Write-Output "--- .env.local keys (values hidden) ---"
Get-Content "C:\STEP\step-ai-gateway\.env.local" | ForEach-Object { if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)=') { $matches[1] + '=<set>' } else { $_ } }
