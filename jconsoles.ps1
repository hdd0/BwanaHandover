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
$log = Join-Path $outDir 'jconsoles.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
foreach ($combo in @('ACTION=up,AGENT=windows-vmware,PROJECT=openship', 'ACTION=restart,AGENT=windows-vmware,PROJECT=openship', 'ACTION=up,AGENT=windows-vmware,PROJECT=bwana-data-platform')) {
  try {
    $c = Invoke-WebRequest -Uri ($base + '/job/STEP/job/BwanaPlatform/' + $combo + '/lastBuild/consoleText') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 15
    $safe = $combo.Replace(',', '_').Replace('=', '-')
    Set-Content -LiteralPath (Join-Path $outDir ('console-' + $safe + '.txt')) -Value $c.Content -Encoding UTF8
    JLog ($combo + ' SAVED len=' + $c.RawContentLength)
  } catch { JLog ($combo + ' failed :: ' + $_.Exception.Message) }
}
