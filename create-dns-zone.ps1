$ErrorActionPreference = "Stop"
$pw = ConvertTo-SecureString "BwanaLab!2026#Temp" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("Administrator@ad.bwanakhasu.one", $pw)
Invoke-Command -VMName "BWANA-DC01" -Credential $cred -ScriptBlock {
    $zone = Get-DnsServerZone -Name "bwanakhasu.one" -ErrorAction SilentlyContinue
    if (-not $zone) {
        Add-DnsServerPrimaryZone -Name "bwanakhasu.one" -ZoneFile "bwanakhasu.one.dns" | Out-Null
        Write-Output "CREATED zone bwanakhasu.one"
    } else {
        Write-Output ("Zone exists: " + $zone.ZoneName + " type=" + $zone.ZoneType)
    }
    $rec = Get-DnsServerResourceRecord -ZoneName "bwanakhasu.one" -Name "*.apps" -ErrorAction SilentlyContinue
    if (-not $rec) {
        Add-DnsServerResourceRecord -ZoneName "bwanakhasu.one" -A -Name "*.apps" -IPv4Address "192.168.200.100" -TimeToLive 01:00:00 | Out-Null
        Write-Output "ADDED *.apps.bwanakhasu.one -> 192.168.200.100"
    } else {
        Write-Output "Wildcard already present"
        $rec | Format-List HostName, RecordType, RecordData | Out-String | Write-Output
    }
    # also add api + console A records for OKD (same LB VIP)
    foreach ($n in @("api", "console-openshift-console")) {
        $r = Get-DnsServerResourceRecord -ZoneName "bwanakhasu.one" -Name $n -ErrorAction SilentlyContinue
        if (-not $r) {
            Add-DnsServerResourceRecord -ZoneName "bwanakhasu.one" -A -Name $n -IPv4Address "192.168.200.100" | Out-Null
            Write-Output ("ADDED " + $n + ".bwanakhasu.one -> 192.168.200.100")
        } else {
            Write-Output ($n + ".bwanakhasu.one already present")
        }
    }
}
Write-Output "DNS_DONE"
