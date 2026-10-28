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
$log = Join-Path $outDir 'jprobe.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers @{Authorization = "Basic $pair" } -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
$xml = Get-Content -LiteralPath (Join-Path $outDir 'probe-job.xml') -Raw -Encoding UTF8
try {
  $r = Invoke-WebRequest -Uri ($base + '/job/STEP/createItem?name=_probe-agent') -Method POST -Headers $JH -ContentType 'application/xml' -Body $xml -UseBasicParsing -TimeoutSec 15
  JLog ('CREATE status=' + $r.StatusCode)
} catch { JLog ('CREATE failed :: ' + $_.Exception.Message) }
try {
  $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/_probe-agent/build') -Method POST -Headers $JH -UseBasicParsing -TimeoutSec 15
  JLog ('BUILD-QUEUED status=' + $r.StatusCode)
} catch { JLog ('BUILD-QUEUE failed :: ' + $_.Exception.Message) }
$num = 0
for ($i = 1; $i -le 40; $i++) {
  Start-Sleep -Seconds 5
  try {
    $j = Invoke-RestMethod -Uri ($base + '/job/STEP/job/_probe-agent/api/json?tree=lastBuild[number,building,result]') -Headers @{Authorization = "Basic $pair" } -TimeoutSec 10
    if ($j.lastBuild) {
      $num = $j.lastBuild.number
      if (-not $j.lastBuild.building) { JLog ('BUILD-DONE number=' + $num + ' result=' + $j.lastBuild.result); break }
    }
  } catch { JLog ('POLL failed :: ' + $_.Exception.Message) }
  if ($i -eq 40) { JLog 'POLL-TIMEOUT' }
}
if ($num -gt 0) {
  try {
    $c = Invoke-WebRequest -Uri ($base + '/job/STEP/job/_probe-agent/' + $num + '/consoleText') -Headers @{Authorization = "Basic $pair" } -UseBasicParsing -TimeoutSec 15
    Set-Content -LiteralPath (Join-Path $outDir 'probe-console.txt') -Value $c.Content -Encoding UTF8
    JLog 'CONSOLE-SAVED'
  } catch { JLog ('CONSOLE failed :: ' + $_.Exception.Message) }
}
