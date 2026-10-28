Write-Host '=== LM Studio paths ==='
$paths = @('C:\Program Files\LM Studio','C:\Program Files (x86)\LM Studio','C:\Users\howar\AppData\Local\LM Studio','C:\Users\howar\AppData\Roaming\LM Studio')
foreach ($p in $paths) { if (Test-Path $p) { Get-ChildItem $p | Select-Object -First 5 | Format-Table -Auto } else { "NOT FOUND: $p" } }
Write-Host '=== Atomic / proxy scripts ==='
Get-ChildItem 'C:\STEP\gateway-3366' -Filter '*.ps1' -File -ErrorAction SilentlyContinue | Select-Object Name, LastWriteTime | Format-Table -Auto
Write-Host '=== LM Studio MCP start ==='
Get-ChildItem 'C:\STEP\lmstudio-mcp-server' -ErrorAction SilentlyContinue | Select-Object Name | Format-Table -Auto
