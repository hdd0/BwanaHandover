$ErrorActionPreference = 'SilentlyContinue'
$repos = Get-Content C:\Users\howar\AppData\Local\Temp\opencode\repos.txt
$out = foreach ($r in $repos) {
    Push-Location $r
    $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
    $dirty = @(git status --porcelain 2>$null).Count
    $last = (git log -1 --format='%ad|%s' --date=short 2>$null)
    $remote = (git remote get-url origin 2>$null)
    $ahead = $null; $behind = $null
    if ($remote) {
        $ab = git rev-list --left-right --count "HEAD...@{u}" 2>$null
        if ($ab) { $parts = $ab -split '\s+'; $behind = $parts[0]; $ahead = $parts[1] }
    }
    Pop-Location
    [pscustomobject]@{
        Repo     = $r.Replace('C:\STEP\','')
        Branch   = $branch
        Dirty    = $dirty
        Ahead    = $ahead
        Behind   = $behind
        Last     = $last
        Remote   = $remote
    }
}
$out | ConvertTo-Json -Depth 3 | Out-File C:\Users\howar\AppData\Local\Temp\opencode\repos.json -Encoding utf8
$out | Sort-Object Repo | Format-Table Repo,Branch,Dirty,Ahead,Behind,Last -AutoSize
