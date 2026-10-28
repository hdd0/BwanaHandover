Write-Output "--- JetBrains processes ---"
Get-Process | Where-Object { $_.ProcessName -match 'idea|rider|pycharm|jetbrains|bun|opencode' } | Select-Object ProcessName, Id, Path | Format-Table -AutoSize
Write-Output "--- recent JetBrains logs mentioning server/bun ---"
$roots = @("$env:LOCALAPPDATA\JetBrains", "$env:APPDATA\JetBrains", "$env:LOCALAPPDATA\Google\AndroidStudio*")
foreach ($r in $roots) { Get-ChildItem $r -Recurse -Include *.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5 FullName, LastWriteTime | Format-Table -AutoSize }
Write-Output "--- grep for ~BUN / Unexpected server error ---"
$hits = Get-ChildItem "$env:LOCALAPPDATA\JetBrains","$env:APPDATA\JetBrains" -Recurse -Include *.log -ErrorAction SilentlyContinue | Select-String -Pattern 'Unexpected server error|~BUN|chunk-' -SimpleMatch:$false | Select-Object -Last 20
$hits | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line)" }
