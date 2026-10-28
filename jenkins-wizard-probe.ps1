$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))
$headers = @{ Authorization = "Basic $pair" }

$wc = New-Object System.Net.WebClient
$wc.Headers['Authorization'] = "Basic $pair"
try {
    $html = $wc.DownloadString("$url/setupWizard/")
    Write-Host "RESULT: setupWizard page fetched, length=$($html.Length)"
    $forms = [regex]::Matches($html, '<form[^>]*action="([^"]+)"')
    foreach ($f in $forms) { Write-Host "FORM ACTION: $($f.Groups[1].Value)" }
    $inputs = [regex]::Matches($html, '<input[^>]*name="([^"]+)"')
    $names = @(); foreach ($i in $inputs) { $names += $i.Groups[1].Value }
    Write-Host "INPUT NAMES: $($names -join ', ')"
}
catch {
    Write-Host "RESULT: setupWizard fetch FAILED $([int]$_.Exception.Response.StatusCode) $($_.Exception.Message)"
}
