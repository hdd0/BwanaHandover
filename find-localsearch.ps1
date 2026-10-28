Write-Host "=== C:\STEP\local-search ==="
Get-ChildItem 'C:\STEP\local-search' -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime | Format-Table -Auto
Write-Host "=== grep for 3369 in local-search ==="
Get-ChildItem 'C:\STEP\local-search' -Recurse -Include '*.js','*.mjs','*.json','*.ps1','*.md' -File -ErrorAction SilentlyContinue |
  Select-String -Pattern '3369' -SimpleMatch -List -ErrorAction SilentlyContinue |
  Select-Object Path, LineNumber, Line | Format-Table -Auto -Wrap
Write-Host "=== .config\opencode\skill\local-search ==="
Get-ChildItem 'C:\Users\howar\.config\opencode\skill\local-search' -ErrorAction SilentlyContinue | Select-Object Name, Length | Format-Table -Auto
Write-Host "=== gateway-3366 logs (recent) ==="
Get-ChildItem 'C:\STEP\gateway-3366\logs' -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime | Format-Table -Auto
