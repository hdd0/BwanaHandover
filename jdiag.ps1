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
$log = Join-Path $outDir 'jdiag.log'
Remove-Item -LiteralPath $log -ErrorAction SilentlyContinue
function JLog($m) { Add-Content -LiteralPath $log -Value $m }
$me = Invoke-RestMethod -Uri ($base + '/me/api/json?tree=name,id,fullName') -Headers @{Authorization = "Basic $pair" } -TimeoutSec 10
JLog ('ME name=' + $me.name + ' id=' + $me.id + ' fullName=' + $me.fullName)
try {
  $perm = Invoke-WebRequest -Uri ($base + '/job/STEP/') -Headers @{Authorization = "Basic $pair" } -UseBasicParsing -TimeoutSec 10
  JLog ('STEP-page status=' + $perm.StatusCode)
} catch { JLog ('STEP-page :: ' + $_.Exception.Message) }
$crumb = (Invoke-WebRequest -Uri ($base + '/crumbIssuer/api/json') -Headers @{Authorization = "Basic $pair" } -UseBasicParsing -TimeoutSec 10).Content | ConvertFrom-Json
JLog ('CRUMB field=' + $crumb.crumbRequestField + ' len=' + $crumb.crumb.Length)
$req = [System.Net.HttpWebRequest]::Create($base + '/job/STEP/createItem?name=_probe-agent')
$req.Method = 'POST'
$req.Headers['Authorization'] = "Basic $pair"
$req.Headers[$crumb.crumbRequestField] = $crumb.crumb
$req.ContentType = 'application/xml'
$bytes = [Text.Encoding]::UTF8.GetBytes('<project><builders/></project>')
$req.ContentLength = $bytes.Length
$stream = $req.GetRequestStream()
$stream.Write($bytes, 0, $bytes.Length)
$stream.Close()
try {
  $resp = $req.GetResponse()
  JLog ('CREATE status=' + [int]$resp.StatusCode)
  $resp.Close()
} catch [System.Net.WebException] {
  $er = $_.Exception.Response
  JLog ('CREATE status=' + [int]$er.StatusCode)
  $sr = New-Object System.IO.StreamReader($er.GetResponseStream())
  $body = $sr.ReadToEnd()
  $sr.Close()
  Set-Content -LiteralPath (Join-Path $outDir 'jdiag-403.html') -Value $body -Encoding UTF8
  JLog 'BODY-SAVED to jdiag-403.html'
}
