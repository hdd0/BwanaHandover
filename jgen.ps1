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
$log = Join-Path $outDir 'jgen.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }

function ChoiceParam($name, $desc, $opts) {
  $s = "<hudson.model.ChoiceParameterDefinition><name>$name</name><description>$desc</description>"
  $s += '<choices class="java.util.Arrays$ArrayList"><a class="string-array">'
  foreach ($o in $opts) { $s += "<string>$o</string>" }
  return $s + '</a></choices></hudson.model.ChoiceParameterDefinition>'
}
function FreestyleXml($desc, $paramsXml, $batch) {
  return @"
<project>
  <actions/>
  <description>$desc</description>
  <keepDependencies>false</keepDependencies>
  <properties>$paramsXml</properties>
  <scm class="hudson.scm.NullSCM"/>
  <assignedNode>windows-vmware</assignedNode>
  <canRoam>false</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <builders>
    <hudson.tasks.BatchFile>
      <command>$batch</command>
    </hudson.tasks.BatchFile>
  </builders>
  <publishers/>
  <buildWrappers/>
</project>
"@
}
function JCreate($name, $xml) {
  try {
    $r = Invoke-WebRequest -Uri ($base + '/job/STEP/createItem?name=' + $name) -Method POST -Headers $JH -WebSession $session -ContentType 'application/xml' -Body $xml -UseBasicParsing -TimeoutSec 15
    JLog ('CREATE ' + $name + ' status=' + $r.StatusCode)
  } catch { JLog ('CREATE ' + $name + ' failed :: ' + $_.Exception.Message.Split([Environment]::NewLine)[0]) }
}
$actionParam = '<hudson.model.ParametersDefinitionProperty><parameterDefinitions>' + (ChoiceParam 'ACTION' 'Manage action' @('status', 'up', 'restart', 'logs')) + '</parameterDefinitions></hudson.model.ParametersDefinitionProperty>'

$jobs = @(
  @{n = 'Compose-ArchitectApp'; d = 'OpenBao secrets manager stack (architect-app). Runs on windows-vmware agent.'; dir = 'C:\STEP\architect-app'; cf = '--env-file .env.secrets -f docker-compose.secrets.yml' },
  @{n = 'Compose-BwanaDataPlatform'; d = 'Bwana data platform stack (14 services). Runs on windows-vmware agent.'; dir = 'C:\BwanaData'; cf = '-f compose.yaml' },
  @{n = 'Compose-BwanaMusic'; d = 'Bwana music IPTV stack. Runs on windows-vmware agent.'; dir = 'C:\STEP\openship\apps\bwana-music'; cf = '-f docker-compose.standalone.yml' },
  @{n = 'Compose-OpenShip'; d = 'OpenShip platform stack. Runs on windows-vmware agent.'; dir = 'C:\STEP\openship'; cf = '-f docker\docker-compose.yml -f docker-compose.yml' },
  @{n = 'Compose-Firecrawl'; d = 'Firecrawl self-hosted scraping stack. Runs on windows-vmware agent.'; dir = 'C:\BwanaData\vendor\firecrawl'; cf = '-f docker-compose.yaml' }
)
foreach ($j in $jobs) {
  $batch = 'cd /d "' + $j.dir + '"' + [Environment]::NewLine
  $batch += 'if "%ACTION%"=="status" docker compose ' + $j.cf + ' ps' + [Environment]::NewLine
  $batch += 'if "%ACTION%"=="up" docker compose ' + $j.cf + ' up -d' + [Environment]::NewLine
  $batch += 'if "%ACTION%"=="restart" docker compose ' + $j.cf + ' restart' + [Environment]::NewLine
  $batch += 'if "%ACTION%"=="logs" docker compose ' + $j.cf + ' logs --tail 60'
  JCreate $j.n (FreestyleXml $j.d $actionParam $batch)
}

$saParams = '<hudson.model.ParametersDefinitionProperty><parameterDefinitions>' + (ChoiceParam 'TARGET' 'Container (or all)' @('all', 'jenkins', 'vaultwarden', 'architect-openbao', 'glpi', 'glpi-db', 'prometheus', 'grafana', 'africa-infra')) + (ChoiceParam 'ACTION' 'Manage action' @('status', 'up', 'restart', 'logs')) + '</parameterDefinitions></hudson.model.ParametersDefinitionProperty>'
$saBatch = @'
setlocal
if "%TARGET%"=="all" (set SCOPE=jenkins vaultwarden architect-openbao glpi glpi-db prometheus grafana africa-infra) else (set SCOPE=%TARGET%)
if "%ACTION%"=="status" docker ps -a --format "{{.Names}}|{{.Status}}" | findstr /i "%SCOPE: = %"
if "%ACTION%"=="up" for %%c in (%SCOPE%) do docker start %%c
if "%ACTION%"=="restart" for %%c in (%SCOPE%) do docker restart %%c
if "%ACTION%"=="logs" for %%c in (%SCOPE%) do docker logs %%c --tail 30
'@
JCreate 'Standalone-Services' (FreestyleXml 'Standalone docker-run services (jenkins, vaultwarden, openbao, glpi, prometheus, grafana, africa-infra). Runs on windows-vmware agent.' $saParams $saBatch)

$matrixBatch = @'
setlocal
if "%PROJECT%"=="standalone" goto :standalone
if "%PROJECT%"=="architect-app" cd /d C:\STEP\architect-app
if "%PROJECT%"=="bwana-data-platform" cd /d C:\BwanaData
if "%PROJECT%"=="bwana-music" cd /d C:\STEP\openship\apps\bwana-music
if "%PROJECT%"=="openship" cd /d C:\STEP\openship
if "%PROJECT%"=="firecrawl" cd /d C:\BwanaData\vendor\firecrawl
set CMD=%ACTION%
if "%ACTION%"=="up" set CMD=up -d
if "%PROJECT%"=="architect-app" docker compose --env-file .env.secrets -f docker-compose.secrets.yml %CMD%
if "%PROJECT%"=="bwana-data-platform" docker compose -f compose.yaml %CMD%
if "%PROJECT%"=="bwana-music" docker compose -f docker-compose.standalone.yml %CMD%
if "%PROJECT%"=="openship" docker compose -f docker\docker-compose.yml -f docker-compose.yml %CMD%
if "%PROJECT%"=="firecrawl" docker compose -f docker-compose.yaml %CMD%
goto :end
:standalone
if "%ACTION%"=="status" docker ps --format "{{.Names}}|{{.Status}}"
if "%ACTION%"=="up" for %%c in (jenkins vaultwarden architect-openbao glpi glpi-db prometheus grafana africa-infra) do docker start %%c
if "%ACTION%"=="restart" for %%c in (jenkins vaultwarden architect-openbao glpi glpi-db prometheus grafana africa-infra) do docker restart %%c
:end
'@
$matrixXml = @"
<?xml version="1.1" encoding="UTF-8"?>
<matrix-project plugin="matrix-project@917.v22eda_817646e">
  <keepDependencies>false</keepDependencies>
  <properties/>
  <scm class="hudson.scm.NullSCM"/>
  <assignedLabel>windows-vmware</assignedLabel>
  <canRoam>false</canRoam>
  <disabled>false</disabled>
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>
  <triggers/>
  <concurrentBuild>false</concurrentBuild>
  <axes>
    <hudson.matrix.TextAxis>
      <name>PROJECT</name>
      <values>
        <string>architect-app</string>
        <string>bwana-data-platform</string>
        <string>bwana-music</string>
        <string>openship</string>
        <string>firecrawl</string>
        <string>standalone</string>
      </values>
    </hudson.matrix.TextAxis>
    <hudson.matrix.TextAxis>
      <name>ACTION</name>
      <values>
        <string>status</string>
        <string>up</string>
        <string>restart</string>
      </values>
    </hudson.matrix.TextAxis>
  </axes>
  <builders>
    <hudson.tasks.BatchFile>
      <command>$matrixBatch</command>
    </hudson.tasks.BatchFile>
  </builders>
  <publishers/>
  <buildWrappers/>
  <executionStrategy class="hudson.matrix.DefaultMatrixExecutionStrategyImpl">
    <runSequentially>false</runSequentially>
    <scheduleDelayMillis>0</scheduleDelayMillis>
  </executionStrategy>
</matrix-project>
"@
try {
  $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/BwanaPlatform/config.xml') -Method POST -Headers $JH -WebSession $session -ContentType 'application/xml' -Body $matrixXml -UseBasicParsing -TimeoutSec 15
  JLog ('RECONFIG BwanaPlatform status=' + $r.StatusCode)
} catch { JLog ('RECONFIG BwanaPlatform failed :: ' + $_.Exception.Message.Split([Environment]::NewLine)[0]) }

try {
  $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/_probe-agent/doDelete') -Method POST -Headers $JH -WebSession $session -UseBasicParsing -TimeoutSec 15
  JLog ('DELETE _probe-agent status=' + $r.StatusCode)
} catch { JLog ('DELETE _probe-agent failed :: ' + $_.Exception.Message.Split([Environment]::NewLine)[0]) }
