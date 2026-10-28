$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))
$auth = @{ Authorization = "Basic $pair" }

# Keep a cookie session so the CSRF crumb validates against the same session.
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession

try {
    $crumb = Invoke-RestMethod -Uri "$url/crumbIssuer/api/json" -Headers $auth -WebSession $session -TimeoutSec 20
    Write-Host "crumb obtained: $($crumb.crumbRequestField)"
}
catch {
    Write-Host "crumb FAILED: $([int]$_.Exception.Response.StatusCode)"
    exit 1
}

$headers = @{}
foreach ($k in $auth.Keys) { $headers[$k] = $auth[$k] }
$headers[$crumb.crumbRequestField] = $crumb.crumb

$script = 'println("SESSION_SCRIPT_OK")'
try {
    $out = Invoke-RestMethod -Method Post -Uri "$url/scriptText" -Headers $headers -WebSession $session -Body @{ script = $script } -TimeoutSec 30
    Write-Host "scriptText OK -> $($out.Trim())"
}
catch {
    $code = 0
    try { $code = [int]$_.Exception.Response.StatusCode } catch { $code = 'ERR' }
    Write-Host "scriptText FAILED: $code"
    $r = $_.Exception.Response
    if ($r) {
        $reader = New-Object System.IO.StreamReader($r.GetResponseStream())
        Write-Host "body: $($reader.ReadToEnd())"
        $reader.Close()
    }
}
