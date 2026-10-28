$ErrorActionPreference = 'Continue'
$envPath = 'C:\STEP\dynadot-integration\.env'
$cfg = @{}
foreach ($line in [System.IO.File]::ReadAllLines($envPath)) {
    if ($line -match '^\s*#' -or -not $line.Contains('=')) { continue }
    $k = $line.Split('=')[0].Trim(); $v = $line.Split('=',2)[1].Trim().Trim('"').Trim("'")
    $cfg[$k] = $v
}
$key = $null; $sec = $null
foreach ($k in $cfg.Keys) { if ($k -match '(?i)api_?key$') { $key = $cfg[$k] }; if ($k -match '(?i)api_?secret$') { $sec = $cfg[$k] } }
$headers = @{ 'Authorization' = "API-Key $key,API-Secret $sec" }

Write-Output "=== RAW: GET /domain ==="
try {
    $r = Invoke-WebRequest -Uri 'https://api.dynadot.com/restful/v1/domain' -Headers $headers -Method Get -TimeoutSec 45 -UseBasicParsing
    Write-Output ("HTTP {0}" -f $r.StatusCode)
    $body = $r.Content
    Write-Output ("Content-Type: {0} | Length: {1}" -f $r.Headers['Content-Type'], $body.Length)
    if ($body.Length -gt 1200) { $body = $body.Substring(0,1200) + "`n...[truncated]" }
    Write-Output $body
} catch {
    Write-Output ("Invoke-WebRequest failed: {0}" -f $_.Exception.Message)
    if ($_.Exception.Response) {
        $resp = $_.Exception.Response
        Write-Output ("Status: {0}" -f [int]$resp.StatusCode)
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $eb = $sr.ReadToEnd(); $sr.Close()
        if ($eb.Length -gt 800) { $eb = $eb.Substring(0,800) }
        Write-Output ("Body: {0}" -f $eb)
    }
}

Write-Output ""
Write-Output "=== RAW: GET /domain/bwanakhasu.one ==="
try {
    $r2 = Invoke-WebRequest -Uri 'https://api.dynadot.com/restful/v1/domain/bwanakhasu.one' -Headers $headers -Method Get -TimeoutSec 45 -UseBasicParsing
    Write-Output ("HTTP {0}" -f $r2.StatusCode)
    $b2 = $r2.Content
    if ($b2.Length -gt 1500) { $b2 = $b2.Substring(0,1500) + "`n...[truncated]" }
    Write-Output $b2
} catch { Write-Output ("failed: {0}" -f $_.Exception.Message) }

Write-Output ""
Write-Output "=== PUBLIC DNS CHECK (independent of API) ==="
foreach ($d in @('bwanakhasu.one','bwanakhasu.co.za','bwanakhasu.com')) {
    Write-Output "--- $d ---"
    try {
        $ns = Resolve-DnsName -Name $d -Type NS -ErrorAction Stop | Where-Object { $_.Type -eq 'NS' }
        Write-Output ("  NS: {0}" -f (($ns | ForEach-Object { $_.NameHost }) -join ', '))
    } catch { Write-Output "  NS lookup failed: $($_.Exception.Message)" }
    try {
        $mx = Resolve-DnsName -Name $d -Type MX -ErrorAction Stop | Where-Object { $_.Type -eq 'MX' }
        if ($mx) { Write-Output ("  MX: {0}" -f (($mx | ForEach-Object { "$($_.Preference) $($_.NameExchange)" }) -join ', ')) } else { Write-Output "  MX: none published" }
    } catch { Write-Output "  MX: none (no record)" }
    try {
        $spf = Resolve-DnsName -Name $d -Type TXT -ErrorAction Stop | Where-Object { $_.Type -eq 'TXT' }
        $mail = @($spf | Where-Object { ($_.Strings -join '') -match '(?i)v=spf|dmarc' })
        if ($mail.Count) { $mail | ForEach-Object { $s = ($_.Strings -join ''); if ($s.Length -gt 120) { $s = $s.Substring(0,120)+'...' }; Write-Output "  TXT: $s" } } else { Write-Output "  SPF/DMARC TXT: none" }
    } catch { Write-Output "  TXT: none" }
}