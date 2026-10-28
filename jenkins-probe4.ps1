$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

# 1. Fetch the CLI jar the server publishes.
$jarPath = Join-Path $env:TEMP 'jenkins-cli.jar'
try {
    Invoke-WebRequest -UseBasicParsing -Uri "$url/jnlpJars/jenkins-cli.jar" -OutFile $jarPath -TimeoutSec 60
    Write-Host "CLI JAR: downloaded $((Get-Item $jarPath).Length) bytes"
}
catch {
    Write-Host "CLI JAR: download FAILED $([int]$_.Exception.Response.StatusCode)"
}

# 2. Retry scriptText with an explicit crumb header (no secrets printed).
$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))

$crumb = $null
try {
    $c = Invoke-RestMethod -Uri "$url/crumbIssuer/api/json" -Headers @{ Authorization = "Basic $pair" } -TimeoutSec 20
    $crumbField = $c.crumbRequestField
    $crumbValue = $c.crumb
    Write-Host "CRUMB: obtained (field=$crumbField)"
}
catch {
    Write-Host "CRUMB: FAILED $([int]$_.Exception.Response.StatusCode)"
}

if ($crumbField) {
    $headers = @{
        Authorization  = "Basic $pair"
        $crumbField    = $crumbValue
    }
    try {
        $resp = Invoke-RestMethod -Method Post -Uri "$url/scriptText" -Headers $headers -Body @{ script = 'println("SCRIPT_CONSOLE_OK")' } -TimeoutSec 30
        Write-Host "SCRIPT CONSOLE: OK -> $($resp.Trim())"
    }
    catch {
        Write-Host "SCRIPT CONSOLE: FAILED $([int]$_.Exception.Response.StatusCode)"
    }
}
