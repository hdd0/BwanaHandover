$ErrorActionPreference = 'Continue'
$hold = @('BwanaApp')
$existing = @(gh repo list hdd0 --limit 200 --json name --jq '.[].name')
$ok = @(); $fail = @()
Get-ChildItem -LiteralPath 'C:\STEP' -Directory -Filter 'Bwana*' | ForEach-Object {
    $name = $_.Name
    if ($hold -contains $name) { return }
    $path = $_.FullName
    if ($existing -contains $name) { return }
    $rem = (git -C $path remote get-url origin 2>$null)
    if (-not $rem) { return }
    Write-Output "=== $name ==="
    $branch = (git -C $path rev-parse --abbrev-ref HEAD 2>$null)
    $ver = if (Test-Path -LiteralPath "$path\VERSION") { (Get-Content -LiteralPath "$path\VERSION" -ErrorAction SilentlyContinue | Select-Object -First 1) } else { '' }
    gh repo create "hdd0/$name" --private --description "Bwana project: $name" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $fail += "$name (create)"; Write-Output "  CREATE FAILED"; return }
    $tags = @(git -C $path tag)
    if ($tags.Count -gt 0) {
        foreach ($t in $tags) { git -C $path push origin "refs/tags/$t" --force 2>&1 | Out-Null }
    } else {
        if ($ver) { git -C $path tag "v$ver" 2>&1 | Out-Null; git -C $path push origin "refs/tags/v$ver" 2>&1 | Out-Null }
    }
    git -C $path push origin "HEAD:refs/heads/$branch" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $ok += "$name@$ver"; Write-Output "  PUSHED $branch $(if($ver){'v'+$ver})" }
    else { $fail += "$name (push)"; Write-Output "  PUSH FAILED" }
    Start-Sleep -Milliseconds 1200
}
Write-Output ""
Write-Output "===== SUMMARY ====="
Write-Output "OK ($($ok.Count)): $($ok -join ', ')"
Write-Output "FAIL ($($fail.Count)): $($fail -join ', ')"
