$ErrorActionPreference = 'Continue'
# Authoritative read via WMI (MSFT_VirtualMachine), not the property object
$ns = 'root\virtualization\v2'
foreach ($n in 'BWANA-DC01','BWANA-DC02') {
    $c = Get-CimInstance -Namespace $ns -ClassName MSFT_VirtualMachine -Filter "ElementName='$n'" -ErrorAction SilentlyContinue
    if ($c) {
        Write-Host "$n : SecureBootEnabled=$($c.SecureBootEnabled)  SecureBootTemplate=$($c.SecureBootTemplate)  State=$($c.State)  Gen=$($c.Generation)"
    } else { Write-Host "$n : WMI query returned null" }
}
Write-Host ""
Write-Host "--- VM integration service (UEFI/integration) ---"
Get-VM -Name BWANA-DC02 | Select-Object Name,State,Generation,Version,Status,Heartbeat | Format-List
