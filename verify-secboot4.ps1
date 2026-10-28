$ErrorActionPreference = 'Continue'
foreach ($n in 'BWANA-DC01','BWANA-DC02') {
    $fw = Get-VMFirmware -VMName $n
    Write-Host ("{0,-14} SecureBoot={1}  Template={2}" -f $n, $fw.SecureBoot, $fw.SecureBootTemplate)
}
