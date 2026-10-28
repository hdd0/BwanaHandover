$repos = @('BwanaPlatform','BwanaMail','BwanaAI','BwanaWiki','BwanaFinances')
$out = @()
foreach ($r in $repos) {
    $path = "C:\STEP\$r"
    if (Test-Path (Join-Path $path ".git")) {
        Push-Location $path | Out-Null
        $status = git status --short --branch 2>&1 | Out-String
        $out += "=== $r ===\n$status"
        Pop-Location | Out-Null
    }
}
$out | Set-Content -Path 'C:\Users\howar\AppData\Local\Temp\opencode\repo-statuses.txt' -Encoding UTF8
Write-Host "Status written to repo-statuses.txt"
