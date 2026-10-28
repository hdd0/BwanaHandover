$ErrorActionPreference = 'Continue'
$out = @()
$existing = @(gh repo list hdd0 --limit 200 --json name --jq '.[].name')
Get-ChildItem -LiteralPath 'C:\STEP' -Directory -Filter 'Bwana*' | Sort-Object Name | ForEach-Object {
    $name = $_.Name
    $path = $_.FullName
    $gitRoot = $path
    if ($name -eq 'BwanaAI') { $gitRoot = "$path\BwanaAI" }
    $isGit = Test-Path -LiteralPath "$gitRoot\.git"
    $ver = ''
    $vf = Join-Path $path 'VERSION'
    if (Test-Path -LiteralPath $vf) { $ver = [string]((Get-Content -LiteralPath $vf -ErrorAction SilentlyContinue | Select-Object -First 1) -join '') }
    if (-not $ver -and $isGit) {
        $tag = @(git -C $gitRoot tag --sort=-creatordate 2>$null)
        if ($tag.Count -gt 0) { $ver = $tag[0] -replace '^v','' }
    }
    $commits = '-'; $dirty = '-'; $branch = '-'
    if ($isGit) {
        $commits = git -C $gitRoot rev-list --count HEAD 2>$null
        $dirty = @(git -C $gitRoot status --porcelain 2>$null).Count
        $branch = git -C $gitRoot rev-parse --abbrev-ref HEAD 2>$null
    }
    $state = if ($existing -contains $name) { 'published' } else { 'pending' }
    $out += [pscustomobject]@{
        Name = $name; Version = if ($ver) { $ver } else { 'n/a' }
        Git = $isGit; Commits = $commits; Dirty = $dirty; Branch = $branch; State = $state
    }
}
$out | ConvertTo-Json -Depth 3

