# Append MX/SPF/mail A/autodiscover/DMARC on Dynadot-managed DNS. Never print the API key.
$ErrorActionPreference = 'Stop'
$OutDir = 'C:\STEP\BwanaMail\data\dns-backups'
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$publicIp = '105.245.28.137'

$key = $null
foreach ($line in Get-Content 'C:\STEP\dynadot-integration\.env') {
    if ($line -match '^\s*DYNADOT_API_KEY\s*=\s*(.+)\s*$') { $key = $Matches[1].Trim().Trim('"') }
}
if (-not $key) { throw 'API key reference missing' }

function Invoke-D([string]$Query) {
    $uri = 'https://api.dynadot.com/api3.json?key=' + $key + '&' + $Query
    $r = Invoke-WebRequest -Uri $uri -TimeoutSec 45 -UseBasicParsing
    return ($r.Content | ConvertFrom-Json)
}

# Domains whose public NS is Dynadot (from prior inventory). .one is Cloudflare — skip.
$domains = @('bwanakhasu.co.za','bwanakhasu.com','umutungumuntutabantu.co.za')
$log = New-Object System.Collections.Generic.List[string]

foreach ($domain in $domains) {
    $log.Add("=== $domain ===")
    try {
        $g = Invoke-D ("command=get_dns&domain=" + [uri]::EscapeDataString($domain))
        $code = [string]$g.GetDnsResponse.ResponseCode
        $log.Add("get_dns code=$code status=$($g.GetDnsResponse.Status)")
        if ($code -ne '0') { $log.Add('SKIP write — get_dns not successful'); continue }
        $bk = Join-Path $OutDir "$domain-dns-prewrite-$stamp.json"
        $g | ConvertTo-Json -Depth 12 | Out-File -LiteralPath $bk -Encoding utf8
        $log.Add("backup=$bk")
    } catch {
        $log.Add("get_dns exception=$($_.Exception.Message)")
        continue
    }

    $mailHost = "mail.$domain"
    $spf = [uri]::EscapeDataString("v=spf1 mx a:mail.$domain ip4:${publicIp} ~all")
    $dmarc = [uri]::EscapeDataString("v=DMARC1; p=none; rua=mailto:dmarc@$domain")
    $q = @(
        'command=set_dns2',
        "domain=$domain",
        'add_dns_to_current_setting=1',
        'main_record_type0=mx',
        ("main_record0=" + [uri]::EscapeDataString($mailHost)),
        'main_recordx0=10',
        'main_record_type1=txt',
        "main_record1=$spf",
        'subdomain0=mail',
        'sub_record_type0=a',
        "sub_record0=$publicIp",
        'subdomain1=autodiscover',
        'sub_record_type1=a',
        "sub_record1=$publicIp",
        'subdomain2=_dmarc',
        'sub_record_type2=txt',
        "sub_record2=$dmarc"
    ) -join '&'
    try {
        $s = Invoke-D $q
        $resp = $s.SetDnsResponse
        if (-not $resp) { $resp = $s.SetDns2Response }
        $log.Add("set_dns2 code=$($resp.ResponseCode) status=$($resp.Status) error=$($resp.Error)")
    } catch {
        $log.Add("set_dns2 exception=$($_.Exception.Message)")
    }
}

$logPath = Join-Path $OutDir "mx-append-$stamp.log"
$log | Set-Content -LiteralPath $logPath -Encoding utf8
$log | ForEach-Object { Write-Host $_ }
Write-Host "LOG=$logPath"
