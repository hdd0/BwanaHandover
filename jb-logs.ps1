$pat = 'Unexpected server error|~BUN|opencode|bun'
Write-Output "--- Rider idea.log matches ---"
Select-String -Path "$env:LOCALAPPDATA\JetBrains\Rider2026.2\log\idea.log" -Pattern $pat -CaseSensitive:$false -ErrorAction SilentlyContinue | Select-Object -Last 15 | ForEach-Object { "$($_.LineNumber): $($_.Line)" }
Write-Output "--- backend log matches ---"
Get-ChildItem "$env:LOCALAPPDATA\JetBrains\Rider2026.2\log" -Filter "backend*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { Select-String -Path $_.FullName -Pattern $pat -CaseSensitive:$false | Select-Object -Last 15 | ForEach-Object { "$($_.LineNumber): $($_.Line)" } }
Write-Output "--- opencode log dirs ---"
Get-ChildItem "$env:USERPROFILE\.local\share\opencode\log","$env:APPDATA\ai.opencode.desktop" -Recurse -Include *.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5 FullName, LastWriteTime | Format-Table -AutoSize
