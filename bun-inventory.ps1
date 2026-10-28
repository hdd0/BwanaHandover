Write-Output "--- bun executables on PATH/disk ---"
where.exe bun 2>$null
Get-ChildItem "$env:USERPROFILE\.bun" -ErrorAction SilentlyContinue | Select-Object FullName | Format-Table -HideTableHeaders
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Directory -Filter "Oven-sh.Bun*" -ErrorAction SilentlyContinue | Select-Object FullName | Format-Table -HideTableHeaders
Write-Output "--- winget registration ---"
winget list --id Oven-sh.Bun --accept-source-agreements 2>$null
Write-Output "--- bun global cache/install dirs ---"
Test-Path "$env:USERPROFILE\.bun\install" ; Test-Path "$env:USERPROFILE\.bun\install\cache"
