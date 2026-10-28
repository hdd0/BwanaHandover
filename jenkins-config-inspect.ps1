$ErrorActionPreference = 'Continue'
$container = 'jenkins'

docker exec $container sh -lc 'echo "--- jobs ---"; ls /var/jenkins_home/jobs 2>/dev/null || echo "(no jobs dir)"; echo "--- users ---"; ls /var/jenkins_home/users 2>/dev/null || echo "(no users dir)"; echo "--- config.xml size ---"; wc -c /var/jenkins_home/config.xml' 2>&1 | ForEach-Object { Write-Host $_ }

$local = Join-Path $env:TEMP 'jenkins-config.xml'
docker cp "${container}:/var/jenkins_home/config.xml" $local | Out-Null
Write-Host "--- pulled config.xml to $local ---"

$xml = Get-Content -LiteralPath $local -Raw
Write-Host "useSecurity line: $([regex]::Match($xml, '<useSecurity>[^<]*</useSecurity>').Value)"
Write-Host "securityRealm:    $([regex]::Match($xml, '<securityRealm class=\"[^\"]*\"').Value)"
Write-Host "authStrategy:     $([regex]::Match($xml, '<authorizationStrategy class=\"[^\"]*\"').Value)"
Write-Host "markupFormatter:  $([regex]::Match($xml, '<markupFormatter>[^<]*</markupFormatter>').Value)"
Write-Host "numExecutors:     $([regex]::Match($xml, '<numExecutors>[^<]*</numExecutors>').Value)"
