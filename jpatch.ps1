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
$log = Join-Path $outDir 'jpatch.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
$oldFull = 'for %%c in (jenkins vaultwarden architect-openbao glpi glpi-db prometheus grafana africa-infra) do docker restart %%c'
$newSafe = 'for %%c in (vaultwarden glpi glpi-db prometheus grafana africa-infra) do docker restart %%c'
$oldScope = 'for %%c in (%SCOPE%) do docker restart %%c'
foreach ($job in @('Standalone-Services', 'BwanaPlatform')) {
  $cfg = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
  $n1 = ([regex]::Matches($cfg, [regex]::Escape($oldFull))).Count
  $n2 = ([regex]::Matches($cfg, [regex]::Escape($oldScope))).Count
  JLog ($job + ' matches full=' + $n1 + ' scope=' + $n2)
  $cfg = $cfg.Replace($oldFull, $newSafe).Replace($oldScope, $newSafe.Replace('%%c', '%%c'))
  if ($job -eq 'Standalone-Services') {
    $cfg = $cfg.Replace('Runs on windows-vmware agent.', 'Runs on windows-vmware agent. Restart excludes jenkins+openbao (self-preservation).')
  }
  try {
    $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Method POST -Headers $JH -WebSession $session -ContentType 'application/xml' -Body $cfg -UseBasicParsing -TimeoutSec 15
    JLog ($job + ' RECONFIG status=' + $r.StatusCode)
  } catch { JLog ($job + ' RECONFIG failed :: ' + $_.Exception.Message) }
  $cfg2 = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/' + $job + '/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
  JLog ($job + ' VERIFY safe-restart=' + $cfg2.Contains($newSafe))
}
