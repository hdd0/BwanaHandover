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
$log = Join-Path $outDir 'jfixlabel.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
$cfg = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/BwanaPlatform/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
JLog ('HAS-assignedLabel=' + $cfg.Contains('<assignedLabel>'))
JLog ('HAS-assignedNode=' + $cfg.Contains('<assignedNode>'))
$cfg = $cfg.Replace('<assignedLabel>windows-vmware</assignedLabel>', '<assignedNode>windows-vmware</assignedNode>')
try {
  $r = Invoke-WebRequest -Uri ($base + '/job/STEP/job/BwanaPlatform/config.xml') -Method POST -Headers $JH -WebSession $session -ContentType 'application/xml' -Body $cfg -UseBasicParsing -TimeoutSec 15
  JLog ('RECONFIG status=' + $r.StatusCode)
} catch { JLog ('RECONFIG failed :: ' + $_.Exception.Message) }
$cfg2 = (Invoke-WebRequest -Uri ($base + '/job/STEP/job/BwanaPlatform/config.xml') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content
JLog ('VERIFY assignedNode=' + $cfg2.Contains('<assignedNode>windows-vmware</assignedNode>'))
