$ErrorActionPreference = 'Continue'
$envPath = 'C:\STEP\dynadot-integration\.env'
$cfg = @{}
foreach ($line in [System.IO.File]::ReadAllLines($envPath)) {
    if ($line -match '^\s*#' -or -not $line.Contains('=')) { continue }
    $k = $line.Split('=')[0].Trim(); $v = $line.Split('=',2)[1].Trim().Trim('"').Trim("'")
    $cfg[$k] = $v
}
$key = $null
foreach ($k in $cfg.Keys) { if ($k -match '(?i)api_?key$') { $key = $cfg[$k] } }
if (-not $key) { Write-Output "no key"; exit 1 }

Write-Output "=== API3 get_dns : bwanakhasu.co.za ==="
try {
    $u = "https://api.dynadot.com/api3.json?key=$key&command=get_dns&domain=bwanakhasu.co.za"
    $r = Invoke-WebRequest -Uri $u -TimeoutSec 45 -UseBasicParsing
    Write-Output ("HTTP {0}" -f $r.StatusCode)
    $j = $r.Content | ConvertFrom-Json
    if ($j.PSObject.Properties.Name -contains 'status') { Write-Output ("status=" + $j.status) }
    if ($j.PSObject.Properties.Name -contains 'error') { Write-Output ("error=" + $j.error) }
    $raw = $r.Content
    Write-Output ("length: {0}" -f $raw.Length)
    if ($raw.Length -gt 2500) { $raw = $raw.Substring(0,2500) + "`n...[truncated]" }
    Write-Output $raw
} catch { Write-Output ("failed: {0}" -f $_.Exception.Message) }