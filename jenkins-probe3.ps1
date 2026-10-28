$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$url = 'http://127.0.0.1:8081'

$init = (docker exec $container sh -lc 'cat /var/jenkins_home/secrets/initialAdminPassword' 2>$null | Out-String).Trim()
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:$init"))
$wc = New-Object System.Net.WebClient
$wc.Headers['Authorization'] = "Basic $pair"

function Probe([string]$label, [string]$path) {
    try {
        $body = $wc.DownloadString("$url$path")
        $snippet = ($body -replace '\s+', ' ')
        if ($snippet.Length -gt 160) { $snippet = $snippet.Substring(0, 160) }
        Write-Host "$label -> 200  $snippet"
    }
    catch {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch { $code = 'ERR' }
        Write-Host "$label -> $code"
    }
}

Probe 'me/api/json'        '/me/api/json?tree=id,anonymous'
Probe 'setupWizardInstance' '/setupWizard/setupWizardInstance'
Probe 'installState'        '/setupWizard/installState'
Probe 'createAdminUser'     '/setupWizard/createAdminUser'
Probe 'setup'              '/setupWizard/setup'
Probe 'whoAmI'              '/api/json?tree=useSecurity'
