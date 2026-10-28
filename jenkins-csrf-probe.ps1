$ErrorActionPreference = 'Continue'
$url = 'http://127.0.0.1:8081'
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

Write-Host 'Step 1: fetch crumb with cookie session...'
try {
    $c = Invoke-RestMethod -Uri "$url/crumbIssuer/api/json" -WebSession $session -TimeoutSec 20
    Write-Host "  crumb obtained: $($c.crumbRequestField)"
}
catch {
    Write-Host "  FAILED $([int]$_.Exception.Response.StatusCode) $($_.Exception.Message)"
    exit 1
}

Write-Host "  cookies held: $($session.Cookies.Count)"

$headers = @{ $c.crumbRequestField = $c.crumb }
Write-Host 'Step 2: POST scriptText with same session...'
try {
    $o = Invoke-RestMethod -Method Post -Uri "$url/scriptText" -Headers $headers -WebSession $session -Body @{ script = 'println("SESSION_OK")' } -TimeoutSec 30
    Write-Host "  OK: $($o.Trim())"
}
catch {
    $code = 0
    try { $code = [int]$_.Exception.Response.StatusCode } catch { $code = 'ERR' }
    Write-Host "  FAILED $code $($_.Exception.Message)"
}
