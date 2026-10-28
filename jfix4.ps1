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
$log = Join-Path $outDir 'jfix4.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
$new = 'docker compose --project-directory C:\STEP\openship\docker --env-file C:\STEP\openship\.env -p openship -f C:\STEP\openship\docker\docker-compose.yml'
foreach ($job in @('Compose-OpenShip', 'BwanaPlatform')) {
  $cfg = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
  $old = 'docker compose --project-directory C:\STEP\openship -f docker\docker-compose.yml -f docker-compose.yml'
  $n = ([regex]::Matches($cfg, [regex]::Escape($old))).Count
  JLog ($job + ' match=' + $n)
  if ($n -gt 0) {
    $cfg = $cfg.Replace($old, $new)
    try {
      $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Method POST -Headers $JH -WebSession $session -ContentType 'application/xml' -Body $cfg -UseBasicParsing -TimeoutSec 15
      JLog ($job + ' POST=' + $r.StatusCode)
    } catch { JLog ($job + ' POST-FAILED') }
    $cfg2 = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
    JLog ($job + ' VERIFY=' + $cfg2.Contains($new))
  }
}
