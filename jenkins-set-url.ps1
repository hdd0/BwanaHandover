$ErrorActionPreference = 'Stop'
$container = 'jenkins'
$configIn = '/var/jenkins_home/config.xml'
$local = Join-Path $env:TEMP 'jenkins-config-edit.xml'

Write-Host 'Stopping container so Jenkins cannot overwrite the edit on shutdown...'
docker stop $container | Out-Null

docker cp "${container}:$configIn" $local | Out-Null
$xml = Get-Content -LiteralPath $local -Raw

$hasUrl = $xml -match '<url>.*?</url>'
Write-Host "Existing <url> element: $hasUrl"

if (-not $hasUrl) {
    # XStream maps elements by name, so position is not critical, but keeping
    # it near the root element stays readable.
    $xml = $xml -replace '(<hudson[^>]*>)', "`$1`n  <url>http://127.0.0.1:8081/</url>"
    Set-Content -LiteralPath $local -Value $xml -Encoding UTF8 -NoNewline
    docker cp $local "${container}:$configIn" | Out-Null
    Write-Host 'Inserted <url>http://127.0.0.1:8081/</url>' -ForegroundColor Green
}
else {
    Write-Host 'Root URL already present; no change needed.'
}

Write-Host 'Starting container...'
docker start $container | Out-Null

$deadline = (Get-Date).AddSeconds(300)
$ready = $false
while ((Get-Date) -lt $deadline) {
    try {
        if ((Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8081/login' -TimeoutSec 10).StatusCode -eq 200) {
            $ready = $true
            break
        }
    }
    catch { }
    Start-Sleep -Seconds 5
}
if ($ready) { Write-Host 'Jenkins is ready.' -ForegroundColor Green }
else { throw 'Jenkins did not become ready.' }

Remove-Item -LiteralPath $local -Force -ErrorAction SilentlyContinue
