$ErrorActionPreference = 'Continue'
$java = (Get-Command java).Source
$jar = Join-Path $env:TEMP 'jenkins-cli.jar'
$groovy = 'C:\Users\howar\RiderProjects\BwanaPlatform\jenkins\groovy\Set-AdminPassword.groovy'
$out = Join-Path $env:TEMP 'o.txt'
$err = Join-Path $env:TEMP 'e.txt'
$pw = $env:JENKINS_ADMIN_PW

# Download a fresh CLI jar and verify it before using it.
Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8081/jnlpJars/jenkins-cli.jar' -OutFile $jar -TimeoutSec 180
Write-Host "jar downloaded: $((Get-Item $jar).Length) bytes"
Write-Host 'jar manifest main-class:'
& $java -cp $jar org.jenkinsci.main.cli.CLI 2>&1 | Select-Object -First 3 | ForEach-Object { Write-Host "  $_" }

Write-Host '=== who-am-i (unsecured, no auth) ==='
& $java -jar $jar -s 'http://127.0.0.1:8081/' who-am-i 1> $out 2> $err
Write-Host "exit=$LASTEXITCODE"
Write-Host '-- stdout --'; if (Test-Path $out) { Get-Content $out | ForEach-Object { Write-Host "  $_" } }
Write-Host '-- stderr --'; if (Test-Path $err) { Get-Content $err | Select-Object -First 15 | ForEach-Object { Write-Host "  $_" } }

Write-Host ''
Write-Host '=== groovy (unsecured) ==='
& $java -jar $jar -s 'http://127.0.0.1:8081/' groovy = $groovy $pw admin 1> $out 2> $err
Write-Host "exit=$LASTEXITCODE"
Write-Host '-- stdout --'; if (Test-Path $out) { Get-Content $out | ForEach-Object { Write-Host "  $_" } }
Write-Host '-- stderr --'; if (Test-Path $err) { Get-Content $err | Select-Object -First 40 | ForEach-Object { Write-Host "  $_" } }
