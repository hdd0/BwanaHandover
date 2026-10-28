param([string]$Root = "C:\STEP")
$repos = Get-ChildItem -Directory -Path $Root | Where-Object { $_.Name -match '^Bwana' -or $_.Name -match '^(HOWARDDAVIDJAMBO|africa-infra|phil-bridge|-malawi-social-intel|pop-planner|vod|videoondemand)$' }
Write-Host "Found $($repos.Count) repo dirs"
foreach ($r in $repos) {
    $git = Join-Path $r.FullName ".git"
    if (Test-Path $git) {
        Write-Host '=== ' $r.Name ' ===' -ForegroundColor Cyan
        Push-Location $r.FullName
        try {
            git fetch --all 2>&1 | Select-Object -First 3 | ForEach-Object { Write-Host $_ }
        } catch { Write-Host "fetch error: $_" -ForegroundColor Yellow }
        Pop-Location
    }
}
