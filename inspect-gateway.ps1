$d = 'C:\STEP\gateway-3366'
Write-Host "=== gateway-3366 contents ==="
Get-ChildItem $d | Select-Object Name, Length, LastWriteTime | Sort-Object Name | Format-Table -Auto
Write-Host "=== routes / server files ==="
Get-ChildItem $d -Recurse -Filter '*.js' -ErrorAction SilentlyContinue |
  Select-Object FullName, Length | Sort-Object FullName | Format-Table -Auto -Wrap
