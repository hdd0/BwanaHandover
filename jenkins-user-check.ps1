$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$local = Join-Path $env:TEMP 'admin-user.xml'
docker cp "${container}:/var/jenkins_home/users/admin_a4b2ba36f6384f9885c14f43fe11cef3b3d6721b96943b41655b6c50a0173e0b/config.xml" $local | Out-Null
$xml = Get-Content -LiteralPath $local -Raw
$xml = $xml -replace '(<passwordHash>)([^<]{0,12})[^<]*(</passwordHash>)', '$1$2...$3'
Write-Host ($xml -replace '\s+', ' ')
Remove-Item -LiteralPath $local -Force -ErrorAction SilentlyContinue

Write-Host ''
Write-Host '=== web form login test ==='
$pw = $env:JENKINS_ADMIN_PW
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
try {
    $login = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8081/login' -WebSession $session -TimeoutSec 20
    $fields = @{}
    foreach ($m in [regex]::Matches($login.Content, '<input[^>]*name="([^"]+)"[^>]*value="([^"]*)"')) { $fields[$m.Groups[1].Value] = $m.Groups[2].Value }
    Write-Host "form fields: $($fields.Keys -join ', ')"
    $body = @{
        j_username      = 'admin'
        j_password      = $pw
        from            = '/'
        Submit          = 'Sign in'
        $fields['Jenkins-Crumb'] = $fields['Jenkins-Crumb']
    } | Where-Object { $_.Key -ne 'Jenkins-Crumb' }
    $resp = Invoke-WebRequest -UseBasicParsing -Method Post -Uri 'http://127.0.0.1:8081/j_acegi_security_check' -WebSession $session -Body $body -TimeoutSec 30 -MaximumRedirection 0 -ErrorAction SilentlyContinue
    Write-Host "login POST status: $($resp.StatusCode)"
}
catch {
    $code = 0
    try { $code = [int]$_.Exception.Response.StatusCode } catch { }
    Write-Host "login POST failed: $code $($_.Exception.Message)"
}
