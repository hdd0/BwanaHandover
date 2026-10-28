$ErrorActionPreference = 'Continue'
$container = 'jenkins'
$local = Join-Path $env:TEMP 'jenkins-config-verify.xml'
docker cp "${container}:/var/jenkins_home/config.xml" $local | Out-Null

$bytes = [System.IO.File]::ReadAllBytes($local)
$hasBom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
Write-Host "BOM present: $hasBom"
Write-Host "First bytes: $([BitConverter]::ToString($bytes[0..7]))"

$xml = Get-Content -LiteralPath $local -Raw
Write-Host "url element:        $([regex]::Match($xml, '<url>[^<]*</url>').Value)"
Write-Host "useSecurity:        $([regex]::Match($xml, '<useSecurity>[^<]*</useSecurity>').Value)"
Write-Host "securityRealm:      $([regex]::Match($xml, '<securityRealm class="[^"]*"').Value)"
Write-Host "authStrategy:       $([regex]::Match($xml, '<authorizationStrategy class="[^"]*"').Value)"
Write-Host "nodeDescription:    $([regex]::Match($xml, '<nodeDescription>[^<]*</nodeDescription>').Value)"
Remove-Item -LiteralPath $local -Force -ErrorAction SilentlyContinue
