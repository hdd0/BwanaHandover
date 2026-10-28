foreach ($d in @('bwanakhasu.one','bwanakhasu.co.za','bwanakhasu.com')) {
  Write-Host "=== $d MX ==="
  Resolve-DnsName -Name $d -Type MX -ErrorAction SilentlyContinue | Select Name,NameExchange,Preference
  Write-Host "=== $d TXT ==="
  Resolve-DnsName -Name $d -Type TXT -ErrorAction SilentlyContinue | Select Name,strings
}
