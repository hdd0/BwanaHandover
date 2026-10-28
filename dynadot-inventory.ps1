$ErrorActionPreference = 'Continue'
$envPath = 'C:\STEP\dynadot-integration\.env'
if (-not (Test-Path $envPath)) { Write-Output "No .env at $envPath"; exit 1 }

# Parse .env WITHOUT echoing values
$cfg = @{}
foreach ($line in [System.IO.File]::ReadAllLines($envPath)) {
    if ($line -match '^\s*#' -or -not $line.Contains('=')) { continue }
    $k = $line.Split('=')[0].Trim()
    $v = $line.Split('=',2)[1].Trim().Trim('"').Trim("'")
    $cfg[$k] = $v
}
$key = $null; $sec = $null
foreach ($k in $cfg.Keys) {
    if ($k -match '(?i)api_?key$') { $key = $cfg[$k] }
    if ($k -match '(?i)api_?secret$') { $sec = $cfg[$k] }
}
if (-not $key -or -not $sec) {
    Write-Output "Could not resolve API key/secret from .env. Keys present:"
    $cfg.Keys | ForEach-Object { Write-Output "  $_" }
    exit 1
}
Write-Output "Credentials loaded from .env (values not shown)."
Write-Output ("Header length: {0}" -f ($key.Length + $sec.Length + 12))
Write-Output ""

$headers = @{ 'Authorization' = "API-Key $key,API-Secret $sec" }
function Get-Dynadot([string]$path) {
    try {
        $r = Invoke-RestMethod -Uri ("https://api.dynadot.com/restful/v1/" + $path) -Headers $headers -Method Get -TimeoutSec 45
        return $r
    } catch { Write-Output ("  ERROR {0}: {1}" -f $path, $_.Exception.Message); return $null }
}

Write-Output "=== DOMAINS ==="
$doms = Get-Dynadot 'domain'
if ($doms) {
    Write-Output ("Total domains: {0}" -f $doms.data.Count)
    $doms.data | ForEach-Object {
        Write-Output ("{0} | {1} | expires {2} | dnssec {3}" -f $_.domain, $_.status, $_.expiry, $_.dnsSec)
    }
    Write-Output ""
    Write-Output "=== NAMESERVERS (who owns DNS per domain) ==="
    foreach ($d in $doms.data) {
        $name = $d.domain
        $info = Get-Dynadot "domain/$name"
        $ns = @()
        if ($info -and $info.data) {
            $ns = $info.data.nameServers
            if (-not $ns) { $ns = @($info.data.PSObject.Properties | Where-Object { $_.Name -eq 'nameServers' } | ForEach-Object { $_.Value }) }
        }
        if (-not $ns -or $ns.Count -eq 0) {
            Write-Output ("{0} : <nameservers not returned>" -f $name)
        } else {
            Write-Output ("{0} : {1}" -f $name, (($ns | Select-Object -First 4) -join ', '))
        }
    }
    Write-Output ""
    Write-Output "=== DNS RECORDS: MX + SPF/DKIM/DMARC TXT (existing mail config) ==="
    foreach ($d in $doms.data) {
        $name = $d.domain
        $rec = Get-Dynadot "domain/$name/dns"
        if (-not $rec -or -not $rec.data) { Write-Output ("{0} : no DNS payload" -f $name); continue }
        $rows = $rec.data
        $mx  = @($rows | Where-Object { $_.type -eq 'MX' })
        $txt = @($rows | Where-Object { $_.type -eq 'TXT' })
        $mailish = @($txt | Where-Object { $_.value -match '(?i)v=spf|dkim|dmarc' })
        Write-Output ("{0} : {1} records | MX={2} | mail TXT={3}" -f $name, $rows.Count, $mx.Count, $mailish.Count)
        foreach ($m in $mx) { Write-Output ("    MX {0} -> {1} (pref {2})" -f $m.name, $m.value, $m.preference) }
        foreach ($t in $mailish) {
            $v = $t.value
            if ($v.Length -gt 110) { $v = $v.Substring(0,110) + '...' }
            Write-Output ("    TXT {0} = {1}" -f $t.name, $v)
        }
    }
}