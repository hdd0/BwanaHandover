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
$log = Join-Path $outDir 'jcombos.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$projects = @('architect-app', 'bwana-data-platform', 'bwana-music', 'openship', 'firecrawl', 'standalone')
$actions = @('status', 'up', 'restart')
foreach ($p in $projects) {
  foreach ($a in $actions) {
    $combo = 'ACTION=' + $a + ',AGENT=windows-vmware,PROJECT=' + $p
    try {
      $c = Invoke-RestMethod -Uri ($base + '/job/STEP/job/BwanaPlatform/job/' + $combo + '/api/json?tree=lastBuild[number,result,building,actions[causes[upstreamBuild]]]&depth=1') -Headers $auth -WebSession $session -TimeoutSec 10
      $up = ''
      foreach ($act in $c.lastBuild.actions) { foreach ($cz in $act.causes) { if ($cz.upstreamBuild) { $up = $cz.upstreamBuild } } }
      JLog ($p + ' ' + $a + ' last=' + $c.lastBuild.number + ' result=' + $c.lastBuild.result + ' building=' + $c.lastBuild.building + ' parent=' + $up)
    } catch { JLog ($p + ' ' + $a + ' QUERY-FAILED') }
  }
}
