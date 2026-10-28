$ErrorActionPreference = 'Continue'
foreach ($d in @('bwanakhasu.one','bwanakhasu.co.za','umutungumuntutabantu.co.za')) {
    Write-Output "================ $d ================"
    foreach ($t in @('NS','MX','A','TXT','CNAME')) {
        try {
            $recs = Resolve-DnsName -Name $d -Type $t -ErrorAction Stop | Where-Object { $_.Type -eq $t }
            if (-not $recs) { Write-Output ("  {0,-5}: (none)" -f $t); continue }
            foreach ($r in $recs) {
                switch ($t) {
                    'MX'    { Write-Output ("  {0,-5}: {1} {2}" -f $t, $r.Preference, $r.NameExchange) }
                    'TXT'   { $s = ($r.Strings -join ''); if ($s.Length -gt 140) { $s = $s.Substring(0,140)+'...' }; Write-Output ("  {0,-5}: {1}" -f $t, $s) }
                    default { Write-Output ("  {0,-5}: {1}" -f $t, $r.($(if($t -eq 'NS'){'NameHost'}elseif($t -eq 'A'){'IPAddress'}else{'NameHost'}))) }
                }
            }
        } catch { Write-Output ("  {0,-5}: (none)" -f $t) }
    }
    Write-Output ""
}
Write-Output "=== MAIL-SPECIFIC SUB-DOMAINS (autodiscover/autoconfig/_dmarc) ==="
foreach ($sub in @('_dmarc.bwanakhasu.co.za','autodiscover.bwanakhasu.co.za','autoconfig.bwanakhasu.co.za','_dmarc.bwanakhasu.one','autodiscover.bwanakhasu.one')) {
    try {
        $r = Resolve-DnsName -Name $sub -ErrorAction Stop
        Write-Output ("  {0} -> {1}" -f $sub, (($r | Where-Object {$_.Type -in @('TXT','CNAME','A')} | ForEach-Object { if($_.Type -eq 'TXT'){($_.Strings -join '')}else{$_.NameHost} }) -join ', '))
    } catch { Write-Output ("  {0} -> (not published)" -f $sub) }
}