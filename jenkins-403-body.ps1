$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))

$c = Invoke-RestMethod -Uri "$url/crumbIssuer/api/json" -Headers @{ Authorization = "Basic $pair" } -TimeoutSec 20
$headers = @{ Authorization = "Basic $pair"; $c.crumbRequestField = $c.crumb }

try {
    Invoke-RestMethod -Method Post -Uri "$url/scriptText" -Headers $headers -Body @{ script = 'println("OK")' } -TimeoutSec 30 | Out-Null
    Write-Host 'scriptText OK'
}
catch {
    $response = $_.Exception.Response
    Write-Host "status: $([int]$response.StatusCode)"
    $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
    $body = $reader.ReadToEnd()
    $reader.Close()
    Write-Host "body: $body"
}

# Also show who we are and our permissions if available
try {
    $me = Invoke-RestMethod -Uri "$url/me/api/json?tree=id,anonymous,absoluteName" -Headers @{ Authorization = "Basic $pair" } -TimeoutSec 20
    Write-Host "identity: id=$($me.id) anonymous=$($me.anonymous)"
}
catch {
    Write-Host "me: $([int]$_.Exception.Response.StatusCode)"
}
