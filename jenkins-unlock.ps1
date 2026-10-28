$ErrorActionPreference = 'Stop'
$container = 'jenkins'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupDir = 'C:\BwanaBackups'
$backupFile = Join-Path $backupDir "jenkins-auth-backup-$stamp.tar.gz"

if (-not (Test-Path -LiteralPath $backupDir)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
}

Write-Host 'Stopping Jenkins...'
docker stop $container | Out-Null

# Back up the auth-related state before touching anything. Only paths that
# actually exist are included, and native stderr must not abort the script.
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'

docker run --rm -v jenkins_home:/data -v "${backupDir}:/backup" -e BAKENAME="$(Split-Path -Leaf $backupFile)" alpine:latest sh -c '
    set -- config.xml secrets jenkins.install.UpgradeWizard.state
    [ -e /data/users ] && set -- "$@" users
    tar -czf "/backup/$BAKENAME" -C /data "$@"
    echo "archived: $@"
' 2>&1 | ForEach-Object { Write-Host $_ }

$ErrorActionPreference = $previous

if (Test-Path -LiteralPath $backupFile) {
    Write-Host "Backup written: $backupFile ($((Get-Item $backupFile).Length) bytes)" -ForegroundColor Green
}
else {
    throw "Backup failed: $backupFile was not created. Nothing was changed."
}

# Jenkins is stopped, so it cannot rewrite these files. A throwaway container
# is used because `docker exec` requires a running container.
Write-Host 'Clearing security state so Jenkins boots unsecured...'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
docker run --rm -v jenkins_home:/data alpine:latest sh -c '
    rm -f /data/config.xml
    rm -rf /data/users
    rm -f /data/secrets/initialAdminPassword
    rm -f /data/jenkins.install.UpgradeWizard.state
' 2>&1 | ForEach-Object { Write-Host $_ }
$ErrorActionPreference = $previous

Write-Host 'Starting Jenkins...'
docker start $container | Out-Null

$deadline = (Get-Date).AddSeconds(300)
$ready = $false
while ((Get-Date) -lt $deadline) {
    try {
        if ((Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8081/login' -TimeoutSec 10).StatusCode -eq 200) { $ready = $true; break }
    }
    catch { }
    Start-Sleep -Seconds 5
}
if ($ready) { Write-Host 'Jenkins is ready and should now be unsecured.' -ForegroundColor Green }
else { throw 'Jenkins did not become ready after the reset.' }
