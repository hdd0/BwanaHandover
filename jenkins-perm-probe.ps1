$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))
$h = @{ Authorization = "Basic $pair" }

function Show([string]$label, [scriptblock]$block) {
    try { $r = & $block; Write-Host "$label -> 200  $r" }
    catch {
        $code = 0; try { $code = [int]$_.Exception.Response.StatusCode } catch { $code = 'ERR' }
        Write-Host "$label -> $code"
    }
}

Show 'GET /script (auth)' { (Invoke-WebRequest -UseBasicParsing -Uri "$url/script" -Headers $h -TimeoutSec 20).StatusCode }
Show 'GET /api/json?depth=0 (auth)' { (Invoke-WebRequest -UseBasicParsing -Uri "$url/api/json?depth=0" -Headers $h -TimeoutSec 20).StatusCode }
Show 'GET /user/admin/api/json (auth)' { (Invoke-WebRequest -UseBasicParsing -Uri "$url/user/admin/api/json" -Headers $h -TimeoutSec 20).StatusCode }
Show 'GET /manage (auth)' { (Invoke-WebRequest -UseBasicParsing -Uri "$url/manage" -Headers $h -TimeoutSec 20).StatusCode }
Show 'POST /scriptText NO crumb' { Invoke-RestMethod -Method Post -Uri "$url/scriptText" -Headers $h -Body @{ script = 'println("NOCRUMB_OK")' } -TimeoutSec 30 }
Show 'GET /crumbIssuer NO auth' { (Invoke-WebRequest -UseBasicParsing -Uri "$url/crumbIssuer/api/json" -TimeoutSec 20).StatusCode }
