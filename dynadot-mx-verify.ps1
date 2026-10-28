$ErrorActionPreference = 'Stop'
$key = $null
foreach ($line in Get-Content 'C:\STEP\dynadot-integration\.env') {
    if ($line -match '^\s*DYNADOT_API_KEY\s*=\s*(.+)\s*$') { $key = $Matches[1].Trim().Trim('"') }
}
function Invoke-D([string]$Query) {
    $uri = 'https://api.dynadot.com/api3.json?key=' + $key + '&' + $Query
    return (Invoke-WebRequest -Uri $uri -TimeoutSec 45 -UseBasicParsing).Content | ConvertFrom-Json
}
foreach ($domain in @('bwanakhasu.co.za','bwanakhasu.com')) {
    Write-Host "=== $domain registrar view ==="
    $g = Invoke-D ("command=get_dns&domain=" + $domain)
    $ns = $g.GetDnsResponse.GetDns.NameServerSettings
    Write-Host ("Type=" + $ns.Type)
    $main = @($ns.MainDomains)
    foreach ($r in $main) {
        $t = $r.RecordType
        $v = [string]$r.Value
        if ($t -eq 'TXT' -and $v.Length -gt 80) { $v = $v.Substring(0,80) + '...' }
        Write-Host ("MAIN {0} {1}" -f $t, $v)
    }
    $subs = @($ns.SubDomains)
    foreach ($r in $subs) {
        Write-Host ("SUB {0} {1} {2}" -f $r.Subhost, $r.RecordType, $r.Value)
    }
}
Write-Host '=== PUBLIC DNS ==='
foreach ($q in @(
    @{N='bwanakhasu.co.za';T='MX'},
    @{N='mail.bwanakhasu.co.za';T='A'},
    @{N='bwanakhasu.com';T='MX'},
    @{N='mail.bwanakhasu.com';T='A'},
    @{N='bwanakhasu.one';T='MX'}
)) {
    try {
        $a = Resolve-DnsName -Name $q.N -Type $q.T -Server 1.1.1.1 -DnsOnly -ErrorAction Stop
        $a | Where-Object { $_.Type -eq $q.T } | ForEach-Object {
            if ($q.T -eq 'MX') { Write-Host ("PUB {0} MX {1} {2}" -f $q.N, $_.Preference, $_.NameExchange) }
            else { Write-Host ("PUB {0} A {1}" -f $q.N, $_.IPAddress) }
        }
    } catch {
        Write-Host ("PUB {0} {1} NONE ({2})" -f $q.N, $q.T, $_.Exception.Message.Split("`n")[0])
    }
}
