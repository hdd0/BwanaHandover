$ErrorActionPreference = 'Stop'
$tokFile = 'C:\STEP\architect-app\.env.secrets'
$tok = ((Get-Content -LiteralPath $tokFile -Raw) | Select-String -Pattern 'OPENBAO_DEV_ROOT_TOKEN=(.+)').Matches.Groups[1].Value.Trim()
$H = @{Authorization = "Bearer $tok" }
$sec = (Invoke-RestMethod 'http://127.0.0.1:8200/v1/secret/data/step/jenkins' -Headers $H -TimeoutSec 8).data.data
$user = [string]$sec.username
$pass = [string]$sec.admin_password
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$user`:$pass"))
$JH = @{Authorization = "Basic $pair" }
$base = 'http://127.0.0.1:8081'
function JGet($path) {
  $u = "$base$path"
  try {
    $r = Invoke-WebRequest -Uri $u -Headers $JH -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Output ("OK " + $path + " [" + $r.StatusCode + "] len=" + $r.RawContentLength)
    return $r.Content
  } catch {
    Write-Output ("FAIL " + $path + " :: " + $_.Exception.Message.Split([Environment]::NewLine)[0])
    return $null
  }
}
$mode = $args[0]
if ($mode -eq 'list') {
  $c = JGet '/job/STEP/api/json?tree=jobs[name,url,color,_class]'
  if ($c) { Write-Output $c.Substring(0, [Math]::Min(3000, $c.Length)) }
} elseif ($mode -eq 'config') {
  $c = JGet '/job/STEP/job/BwanaPlatform/config.xml'
  if ($c) { Write-Output $c.Substring(0, [Math]::Min(6000, $c.Length)) }
} elseif ($mode -eq 'me') {
  $c = JGet '/api/json?tree=nodeName,nodeDescription,numExecutors,version'
  if ($c) { Write-Output $c.Substring(0, [Math]::Min(1500, $c.Length)) }
} elseif ($mode -eq 'plugins') {
  $c = JGet '/pluginManager/api/json?depth=1&tree=plugins[shortName,version,active]'
  if ($c) { Write-Output $c.Substring(0, [Math]::Min(4000, $c.Length)) }
} elseif ($mode -eq 'nodes') {
  $c = JGet '/computer/api/json?tree=computer[displayName,offline,idle,numExecutors]'
  if ($c) { Write-Output $c.Substring(0, [Math]::Min(2000, $c.Length)) }
}
