$ErrorActionPreference = 'Continue'
$container = 'jenkins'

$listing = @'
ls -la /var/jenkins_home
echo "--- jobs ---"
ls -la /var/jenkins_home/jobs 2>/dev/null || echo "(no jobs directory)"
echo "--- users ---"
ls -la /var/jenkins_home/users 2>/dev/null || echo "(no users directory)"
echo "--- nodeMonitors / builds ---"
ls /var/jenkins_home/builds 2>/dev/null || echo "(no builds)"
'@

$local = Join-Path $env:TEMP 'ls-home.sh'
Set-Content -LiteralPath $local -Value $listing -Encoding ascii -NoNewline
docker cp $local "${container}:/tmp/ls-home.sh" | Out-Null
docker exec $container sh /tmp/ls-home.sh 2>&1 | ForEach-Object { Write-Host $_ }
docker exec -u 0 $container sh -c 'rm -f /tmp/ls-home.sh' 2>&1 | Out-Null
Remove-Item -LiteralPath $local -Force -ErrorAction SilentlyContinue
