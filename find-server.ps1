$dir = 'C:\STEP\BwanaPlatform\windows11-integration\ai-control-center'
Write-Host "=== ai-control-center ==="
if (Test-Path $dir) {
  Get-ChildItem $dir | Select-Object Name, LastWriteTime | Format-Table -Auto
} else { Write-Host "NOT FOUND" }
Write-Host "=== server.js ==="
Get-ChildItem -Path $dir -Recurse -Filter 'server.js' -ErrorAction SilentlyContinue | Select-Object FullName, Length | Format-Table -Auto
