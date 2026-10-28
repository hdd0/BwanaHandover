$ErrorActionPreference = 'Stop'
$container = 'jenkins'
$remote = '/var/jenkins_home/jenkins.model.JenkinsLocationConfiguration.xml'
$local = Join-Path $env:TEMP 'jenkins-location.xml'

docker stop $container | Out-Null

$body = @'
<?xml version='1.1' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <adminAddress>address not configured yet &lt;nobody@nowhere&gt;</adminAddress>
  <jenkinsUrl>http://127.0.0.1:8081/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
'@

# PS 5.1 -Encoding UTF8 adds a BOM, which breaks XML parsing. Write without one.
$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($local, $body, $enc)

docker cp $local "${container}:$remote" | Out-Null
Write-Host 'Copied location configuration into the container.' -ForegroundColor Green

# docker cp creates the file as root; Jenkins runs as the jenkins user and must
# be able to rewrite it, so restore ownership and tighten permissions.
docker exec -u 0 $container chown jenkins:jenkins $remote | Out-Null
docker exec -u 0 $container chmod 600 $remote | Out-Null
Write-Host 'Ownership set to jenkins:jenkins (600).'

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
if ($ready) { Write-Host 'Jenkins is ready.' -ForegroundColor Green } else { throw 'Jenkins did not become ready.' }

Remove-Item -LiteralPath $local -Force -ErrorAction SilentlyContinue
