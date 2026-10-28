$ErrorActionPreference = 'Stop'
Set-Location 'C:\STEP\bwana-start'
if (-not (Test-Path .git)) { git init -b main }
$name = git config user.name
$email = git config user.email
if (-not $name) { git config user.name 'Howard David Jambo' }
if (-not $email) { git config user.email 'admin@bwanakhasu.one' }
git add README.md Dockerfile docker-compose.yml .gitignore app public scripts tests data docs
git status --short
git commit -m "feat: add Docker Windows 8 Start board for loopback project links"
git status --short --branch
git log -1 --oneline
