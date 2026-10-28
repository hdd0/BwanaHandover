Write-Output "--- listeners on 3366 ---"
Get-NetTCPConnection -LocalPort 3366 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, State, OwningProcess | Format-Table -AutoSize
Write-Output "--- repo/config files mentioning 3366 ---"
$roots = @("C:\STEP", "$env:USERPROFILE\.config\opencode", "$env:USERPROFILE\.agents")
foreach ($r in $roots) { if (Test-Path $r) { Get-ChildItem $r -Recurse -File -Include *.js,*.mjs,*.ts,*.json,*.yaml,*.yml,*.toml,*.env,*.ps1,*.py,*.md -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 2MB -and $_.FullName -notmatch '\\node_modules\\|\\\.git\\' } | Select-String -Pattern '3366' -SimpleMatch | Select-Object -First 25 | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" } } }
