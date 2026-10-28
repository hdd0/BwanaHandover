$ErrorActionPreference = 'Continue'
Write-Output "=== GH REPOS (hdd0) ==="
& gh repo list hdd0 --limit 100 --json name,visibility,primaryLanguage,updatedAt,pushedAt,diskUsage,isPrivate 2>&1 | Out-String
Write-Output ""
Write-Output "=== BwanaMail exists? ==="
& gh repo view hdd0/BwanaMail 2>&1
Write-Output ""
Write-Output "=== GH RATE / AUTH ==="
& gh auth status 2>&1
Write-Output ""
Write-Output "=== GH CLI VERSION ==="
& gh --version 2>&1
Write-Output ""
Write-Output "=== git identity ==="
& git config --global user.name 2>&1
& git config --global user.email 2>&1