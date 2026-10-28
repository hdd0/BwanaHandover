$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'
$java = (Get-Command java).Source
$jarPath = Join-Path $env:TEMP 'jenkins-cli.jar'
$groovy = 'C:\Users\howar\RiderProjects\BwanaPlatform\jenkins\groovy\Set-AdminPassword.groovy'
$outFile = Join-Path $env:TEMP 'cli-out.txt'
$errFile = Join-Path $env:TEMP 'cli-err.txt'

Invoke-WebRequest -UseBasicParsing -Uri "$url/jnlpJars/jenkins-cli.jar" -OutFile $jarPath -TimeoutSec 120
$initial = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pw = $env:JENKINS_ADMIN_PW

Write-Host '=== who-am-i (sanity) ==='
& $java -jar $jarPath -s "$url/" -auth "admin:$initial" who-am-i 2>&1 | ForEach-Object { Write-Host "  $_" }

Write-Host '=== groovy run ==='
& $java -jar $jarPath -s "$url/" -auth "admin:$initial" groovy = $groovy $pw admin 1> $outFile 2> $errFile
Write-Host "exit=$LASTEXITCODE"
Write-Host '--- stdout ---'
if (Test-Path $outFile) { Get-Content $outFile | ForEach-Object { Write-Host "  $_" } }
Write-Host '--- stderr ---'
if (Test-Path $errFile) { Get-Content $errFile | Select-Object -First 30 | ForEach-Object { Write-Host "  $_" } }
