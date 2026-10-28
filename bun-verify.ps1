Write-Output "--- after purge ---"
Remove-Item -Force "$env:LOCALAPPDATA\Microsoft\WinGet\Links\bun.exe" -ErrorAction SilentlyContinue
Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Directory -Filter "Oven-sh.Bun*" -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item -Recurse -Force $_.FullName }
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
Get-Command bun -All | Format-Table CommandType, Source -AutoSize
& bun --version
