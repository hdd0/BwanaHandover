$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

# Read initial admin password into memory inside the container, never printed.
$init = docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null
$init = ($init | Out-String).Trim()

if (-not $init) { Write-Host 'RESULT: no initialAdminPassword present'; exit 1 }

$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))
$headers = @{ Authorization = "Basic $pair" }

# Does basic auth with the initial password work at all?
try {
    $r = Invoke-RestMethod -Uri "$url/api/json?tree=mode" -Headers $headers -TimeoutSec 20
    Write-Host "RESULT: api_auth=OK mode=$($r.mode)"
}
catch {
    Write-Host "RESULT: api_auth=FAIL $([int]$_.Exception.Response.StatusCode)"
}

# Crumb for POST
$crumb = $null
try {
    $c = Invoke-RestMethod -Uri "$url/crumbIssuer/api/json" -Headers $headers -TimeoutSec 20
    $crumb = @{ $c.crumbRequestField = $c.crumb }
    Write-Host "RESULT: crumb=OK"
}
catch {
    Write-Host "RESULT: crumb=FAIL $([int]$_.Exception.Response.StatusCode)"
}

# Does the script console accept it pre-wizard?
$probeScript = 'println("SCRIPT_CONSOLE_OK")'
try {
    $body = @{ script = $probeScript }
    $resp = Invoke-RestMethod -Method Post -Uri "$url/scriptText" -Headers ($headers + $crumb) -Body $body -TimeoutSec 30
    Write-Host "RESULT: scriptText=OK output=$($resp.Trim())"
}
catch {
    Write-Host "RESULT: scriptText=FAIL $([int]$_.Exception.Response.StatusCode) $($_.Exception.Message)"
}
