$ErrorActionPreference = 'Continue'
Write-Output "=== DC IPs ==="
foreach ($vm in @('BWANA-DC01','BWANA-DC02','BWANA-GOLDEN-SRC','BWANA-NAS-01')) {
    $ips = (Get-VM -Name $vm).NetworkAdapters.IPAddresses -join ', '
    Write-Output "$vm : $ips"
}
Write-Output ""
Write-Output "=== E:\BWANA\Data\ExchangeData ==="
if (Test-Path 'E:\BWANA\Data\ExchangeData') {
    Get-ChildItem 'E:\BWANA\Data\ExchangeData' -Recurse -Depth 2 | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
} else { Write-Output "absent" }
Write-Output ""
Write-Output "=== AD: Exchange schema/objects via ADSI (from host, DC01) ==="
$dcIP = ((Get-VM -Name 'BWANA-DC01').NetworkAdapters.IPAddresses | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
Write-Output "Using DC01 IP: $dcIP"
if ($dcIP) {
    try {
        $schemaNC = [ADSI]"LDAP://$dcIP/CN=Schema,CN=Configuration,DC=ad,DC=bwanakhasu,DC=one"
        $sv = [ADSI]"LDAP://$dcIP/CN=ms-Exch-Schema-Version-Pt,CN=Schema,CN=Configuration,DC=ad,DC=bwanakhasu,DC=one"
        Write-Output "Exchange schema rangeUpper: $($sv.rangeUpper)"
    } catch { Write-Output "No Exchange schema (or bind failed): $($_.Exception.Message)" }
    try {
        $cfg = [ADSI]"LDAP://$dcIP/CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=ad,DC=bwanakhasu,DC=one"
        Write-Output "Exchange Services container: EXISTS"
    } catch { Write-Output "No Exchange Services container: $($_.Exception.Message)" }
    try {
        $searcher = New-Object DirectoryServices.DirectorySearcher([ADSI]"LDAP://$dcIP/CN=Computers,DC=ad,DC=bwanakhasu,DC=one")
        $searcher.Filter = '(objectClass=computer)'
        $searcher.PropertiesToLoad.Add('name') | Out-Null
        $comps = $searcher.FindAll()
        Write-Output "Computers in Computers container:"
        $comps | ForEach-Object { Write-Output "  - $($_.Properties['name'])" }
    } catch { Write-Output "Computer query failed: $($_.Exception.Message)" }
}
Write-Output ""
Write-Output "=== GOLDEN-SRC OS state ==="
$gs = Get-VM -Name 'BWANA-GOLDEN-SRC'
Write-Output "State: $($gs.State), Heartbeat: $($gs.Heartbeat), Uptime: $($gs.Uptime)"
