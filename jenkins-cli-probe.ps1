$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()

$probe = @'
set -x
cd /tmp
rm -rf cliextract
mkdir -p cliextract
cd cliextract
/opt/java/openjdk/bin/jar xf /usr/share/jenkins/jenkins.war WEB-INF/lib/jenkins-cli.jar
ls -l WEB-INF/lib/jenkins-cli.jar
INIT=$(cat /var/jenkins_home/secrets/initialAdminPassword)
/opt/java/openjdk/bin/java -jar /tmp/cliextract/WEB-INF/lib/jenkins-cli.jar -s http://localhost:8080/ -auth "admin:$INIT" who-am-i
'@

$localProbe = Join-Path $env:TEMP 'cli-probe.sh'
Set-Content -LiteralPath $localProbe -Value $probe -Encoding ascii -NoNewline
docker cp $localProbe "${container}:/tmp/cli-probe.sh" | Out-Null
docker exec $Container sh /tmp/cli-probe.sh 2>&1 | ForEach-Object { Write-Host $_ }
docker exec -u 0 $container sh -c 'rm -rf /tmp/cliextract /tmp/cli-probe.sh' 2>&1 | Out-Null
Remove-Item -LiteralPath $localProbe -Force -ErrorAction SilentlyContinue
