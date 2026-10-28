$ErrorActionPreference = 'Stop'
function Emit { param([hashtable]$D, [int]$C = 0) Write-Output 'JSON-HERE'; exit $C }
Write-Host 'before'
Emit @{a=1} 0
Write-Host 'after'
