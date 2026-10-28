<#
    Execute Dynadot API3 mail setup for BwanaMail domains.
    - Loads API key from C:\STEP\dynadot-integration\.env (gitignored) - NEVER prints it.
    - Backs up current DNS before any write.
    - Writes: MX + SPF TXT via set_dns2 (and forwarding via set_email where supported).
    - Emits only non-secret results.
#>
param(
    [switch]$Apply,
    [string]$OutDir = 'C:\STEP\BwanaMail\data\dns-backups'
)
$ErrorActionPreference = 'Stop'

# ---- Load secret reference (value never echoed) ----
$envFile = 'C:\STEP\dynadot-integration\.env'
if (-not (Test-Path $envFile)) { throw "Secret source missing: $envFile" }
$key = $null
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*DYNADOT_API_KEY\s*=\s*"?([^"\r\n]+)"?\s*$') { $key = $Matches[1].Trim() }
}
if (-not $key) { throw 'DYNADOT_API_KEY not found in secret source' }
Write-Host '[ok] Secret reference loaded (value not displayed)'

function Invoke-DynadotApi3 {
    param([string]$Query)
    $uri = "https://api.dynadot.com/api3.json?key=$key&$Query"
    $r = Invoke-WebRequest -Uri $uri -TimeoutSec 45 -UseBasicParsing
    return ($r.Content | ConvertFrom-Json)
}

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$results = @()

# Dynadot-managed mail domains
$targets = @(
    @{ Domain = 'bwanakhasu.co.za';        MxHost = 'mail.bwanakhasu.co.za' }
    @{ Domain = 'umutungumuntutabantu.co.za'; MxHost = 'mail.umutungumuntutabantu.co.za' }
    @{ Domain = 'bwanakhasu.com';         MxHost = 'mail.bwanakhasu.com' }
)

foreach ($t in $targets) {
    $domain = $t.Domain
    Write-Host "`n=== $domain ==="

    # 1. READ + BACKUP (always, before any write)
    try {
        $g = Invoke-DynadotApi3 "command=get_dns&domain=$domain"
        $code = $g.GetDnsResponse.ResponseCode
        if ($code -ne 0) { Write-Host "[FAIL] get_dns: $($g.GetDnsResponse.Status)"; $results += [pscustomobject]@{Domain=$domain;Step='get_dns';Status='FAIL';Detail=$g.GetDnsResponse.Status}; continue }
        $dns = $g.GetDnsResponse.GetDns
        $bk = Join-Path $OutDir "$domain-dns-$stamp.json"
        $dns | ConvertTo-Json -Depth 10 | Out-File -LiteralPath $bk -Encoding utf8
        Write-Host "[ok] Backup written: $bk"
        $existingMx  = @($dns | Where-Object { $_.Type -eq 'MX' } | ForEach-Object { $_.Value })
        $existingTxt = @($dns | Where-Object { $_.Type -eq 'TXT' } | ForEach-Object { $_.Value })
        Write-Host "[info] existing MX:  $(if($existingMx.Count){$existingMx -join ', '}else{'(none)'})"
        Write-Host "[info] existing TXT: $(if($existingTxt.Count){($existingTxt | ForEach-Object { $_.Substring(0,[Math]::Min(60,$_.Length)) }) -join ' | '}else{'(none)'})"
        $results += [pscustomobject]@{Domain=$domain;Step='backup';Status='PASS';Detail=$bk}
    } catch {
        Write-Host "[FAIL] get_dns threw: $($_.Exception.Message)"
        $results += [pscustomobject]@{Domain=$domain;Step='backup';Status='FAIL';Detail=$_.Exception.Message}
        continue
    }

    if (-not $Apply) { Write-Host '[dry-run] write skipped (use -Apply to write)'; continue }

    # 2. WRITE MX + SPF via set_dns2 (add-only semantics, backup already taken)
    try {
        $mx = $t.MxHost
        $spf = 'v=spf1 mx ~all'
        $q = "command=set_dns2&domain=$domain&add_mx=$mx&add_mx_priority=10&add_txt=$spf"
        $s = Invoke-DynadotApi3 $q
        $sc = $s.SetDns2Response.ResponseCode
        $msg = $s.SetDns2Response.Status
        if ($sc -eq 0) { Write-Host "[ok] set_dns2 applied: MX $mx (prio 10) + SPF TXT"; $results += [pscustomobject]@{Domain=$domain;Step='set_dns2';Status='PASS';Detail='MX+SPF added'} }
        else { Write-Host "[FAIL] set_dns2: $msg"; $results += [pscustomobject]@{Domain=$domain;Step='set_dns2';Status='FAIL';Detail=$msg} }
    } catch {
        Write-Host "[FAIL] set_dns2 threw: $($_.Exception.Message)"
        $results += [pscustomobject]@{Domain=$domain;Step='set_dns2';Status='FAIL';Detail=$_.Exception.Message}
    }
}

Write-Host "`n=== SUMMARY ==="
$results | Format-Table -AutoSize | Out-String | Write-Host
$results | ConvertTo-Json -Depth 5 | Out-File -LiteralPath (Join-Path $OutDir "apply-result-$stamp.json") -Encoding utf8
