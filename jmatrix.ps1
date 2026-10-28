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
$job = $args[0]
if ([string]::IsNullOrWhiteSpace($job)) { $job = 'STEP/BwanaPlatform' }
$path = $job.Replace('/', '/job/')
$log = Join-Path $outDir 'jbuild.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
$prev = 0
try {
  $pj = Invoke-RestMethod -Uri ($base + '/job/' + $path + '/api/json?tree=lastBuild[number]') -Headers $auth -WebSession $session -TimeoutSec 10
  if ($pj.lastBuild) { $prev = $pj.lastBuild.number }
} catch {}
JLog ('PREV-BUILD=' + $prev)
$trigger = '/build'
if ($job -ne 'STEP/BwanaPlatform') { $trigger = '/buildWithParameters' }
try {
  $r = Invoke-WebRequest -Uri ($base + '/job/' + $path + $trigger) -Method POST -Headers $JH -WebSession $session -UseBasicParsing -TimeoutSec 15
  JLog ('BUILD-QUEUED status=' + $r.StatusCode)
} catch { JLog ('BUILD-QUEUE failed :: ' + $_.Exception.Message); exit 1 }
$num = 0
for ($i = 1; $i -le 140; $i++) {
  Start-Sleep -Seconds 5
  try {
    $j = Invoke-RestMethod -Uri ($base + '/job/' + $path + '/api/json?tree=lastBuild[number,building,result]') -Headers $auth -WebSession $session -TimeoutSec 10
    if ($j.lastBuild -and $j.lastBuild.number -gt $prev) {
      $num = $j.lastBuild.number
      if (-not $j.lastBuild.building) { JLog ('BUILD-DONE number=' + $num + ' result=' + $j.lastBuild.result); break }
    }
  } catch { JLog ('POLL failed :: ' + $_.Exception.Message) }
  if ($i -eq 140) { JLog 'POLL-TIMEOUT'; exit 1 }
}
try {
  $c = Invoke-WebRequest -Uri ($base + '/job/' + $path + '/' + $num + '/consoleText') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 15
  Set-Content -LiteralPath (Join-Path $outDir 'probe-console.txt') -Value $c.Content -Encoding UTF8
  JLog 'CONSOLE-SAVED'
} catch { JLog ('CONSOLE failed :: ' + $_.Exception.Message) }
