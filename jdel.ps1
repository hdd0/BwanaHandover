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
$log = Join-Path $outDir 'jdel.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$auth = @{Authorization = "Basic $pair" }
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers $auth -WebSession $session -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
$JH = @{Authorization = "Basic $pair"; ($crumb.crumbRequestField) = $crumb.crumb }
$req = [System.Net.HttpWebRequest]::Create($base + '/job/STEP/job/_probe-agent/doDelete')
$req.Method = 'POST'
$req.Headers['Authorization'] = "Basic $pair"
$req.Headers[$crumb.crumbRequestField] = $crumb.crumb
$req.ContentType = 'application/x-www-form-urlencoded'
$req.CookieContainer = $session.Cookies
$bytes = [Text.Encoding]::UTF8.GetBytes('')
$req.ContentLength = $bytes.Length
$stream = $req.GetRequestStream()
$stream.Write($bytes, 0, $bytes.Length)
$stream.Close()
try {
  $resp = $req.GetResponse()
  JLog ('DELETE status=' + [int]$resp.StatusCode)
  $resp.Close()
} catch [System.Net.WebException] {
  $er = $_.Exception.Response
  JLog ('DELETE status=' + [int]$er.StatusCode)
  $sr = New-Object System.IO.StreamReader($er.GetResponseStream())
  $body = $sr.ReadToEnd()
  $sr.Close()
  Set-Content -LiteralPath (Join-Path $outDir 'jdel-403.html') -Value $body -Encoding UTF8
  JLog 'BODY-SAVED to jdel-403.html'
}
