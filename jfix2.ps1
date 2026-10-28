$ErrorActionPreference = 'Stop'
$tokFile = 'C:\STEP\architect-app\.env.secrets'
$tok = ((Get-Content -LiteralPath $tokFile -Raw) | Select-String -Pattern 'OPENBAO_DEV_ROOT_TOKEN=(.+)').Matches.Groups[1].Value.Trim()
$H = @{Authorization = "Bearer $tok" }
$sec = (Invoke-RestMethod 'http://127.0.0.1:8200/v1/secret/data/step/jenkins' -Headers $H -TimeoutSec 8).data.data
$user = [string]$sec.username
$pass = [string]$sec.admin_password
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$user`:$pass"))
$base = 'http://127.0.0.1:8081'
$outDir = 'C:\Users\howar\AppData\Local\Temp\opencode'
$log = Join-Path $outDir 'jfix2.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
function Patch($job, $pairs) {
  $cfg = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
  foreach ($p in $pairs) {
    $n = ([regex]::Matches($cfg, [regex]::Escape($p[0]))).Count
    JLog ($job + ' match=' + $n + ' :: ' + $p[0].Substring(0, [Math]::Min(70, $p[0].Length)))
    $cfg = $cfg.Replace($p[0], $p[1])
  }
  try {
    $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Method POST -Headers $JH -WebSession $session -ContentType 'application/xml' -Body $cfg -UseBasicParsing -TimeoutSec 15
    JLog ($job + ' RECONFIG status=' + $r.StatusCode)
  } catch { JLog ($job + ' RECONFIG failed :: ' + $_.Exception.Message) }
}
$Q = '&quot;'
$NL = '&#xd;'
Patch 'BwanaPlatform' @(
  @('set CMD=%ACTION%', 'set CMD=%ACTION%' + $NL + ' if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'status' + $Q + ' set CMD=ps'),
  @('if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'architect-app' + $Q + ' docker compose --env-file .env.secrets -f docker-compose.secrets.yml %CMD%',
    'if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'architect-app' + $Q + ' if not ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'restart' + $Q + ' docker compose --env-file .env.secrets -f docker-compose.secrets.yml %CMD%' + $NL + ' if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'architect-app' + $Q + ' if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'restart' + $Q + ' echo OpenBao dev-mode: restart SKIPPED to protect in-memory KV'),
  @('if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'bwana-data-platform' + $Q + ' docker compose -f compose.yaml %CMD%',
    'if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'bwana-data-platform' + $Q + ' if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'status' + $Q + ' docker compose -f compose.yaml ps' + $NL + ' if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'bwana-data-platform' + $Q + ' if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'up' + $Q + ' docker compose -f compose.yaml up -d --no-recreate --scale kafka-init=0 --scale minio-init=0' + $NL + ' if ' + $Q + '%PROJECT%' + $Q + '==' + $Q + 'bwana-data-platform' + $Q + ' if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'restart' + $Q + ' docker compose -f compose.yaml restart'),
  @('docker compose -f docker\docker-compose.yml -f docker-compose.yml %CMD%',
    'docker compose --project-directory C:\STEP\openship -f docker\docker-compose.yml -f docker-compose.yml %CMD%')
)
Patch 'Compose-OpenShip' @(
  @('docker compose -f docker\docker-compose.yml -f docker-compose.yml',
    'docker compose --project-directory C:\STEP\openship -f docker\docker-compose.yml -f docker-compose.yml')
)
Patch 'Compose-BwanaDataPlatform' @(
  @('docker compose -f compose.yaml up -d --no-recreate',
    'docker compose -f compose.yaml up -d --no-recreate --scale kafka-init=0 --scale minio-init=0')
)
Patch 'Compose-ArchitectApp' @(
  @('if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'restart' + $Q + ' docker compose --env-file .env.secrets -f docker-compose.secrets.yml restart',
    'if ' + $Q + '%ACTION%' + $Q + '==' + $Q + 'restart' + $Q + ' echo OpenBao dev-mode: restart SKIPPED to protect in-memory KV')
)
