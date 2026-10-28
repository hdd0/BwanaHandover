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
$log = Join-Path $outDir 'jchild.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$bnum = $args[0]
if ([string]::IsNullOrWhiteSpace($bnum)) { $bnum = '1' }
$runs = (Invoke-RestMethod -Uri ($base + '/job/STEP/job/BwanaPlatform/' + $bnum + '/api/json?tree=runs[number,result,url,builtOn]') -Headers $auth -WebSession $session -TimeoutSec 10).runs
foreach ($r in $runs) { JLog ('RUN num=' + $r.number + ' result=' + $r.result + ' builtOn=' + $r.builtOn + ' url=' + $r.url) }
$fail = $runs | Where-Object { $_.result -eq 'FAILURE' } | Select-Object -First 1
if ($fail) {
  $c = Invoke-WebRequest -Uri ($fail.url + 'consoleText') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 15
  Set-Content -LiteralPath (Join-Path $outDir 'child-console.txt') -Value $c.Content -Encoding UTF8
  JLog ('CHILD-CONSOLE-SAVED url=' + $fail.url)
}
