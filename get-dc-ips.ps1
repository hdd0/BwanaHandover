$vms = Get-VM -Name "BWANA-DC01","BWANA-DC02" -ErrorAction SilentlyContinue
foreach ($vm in $vms) {
    $ips = (Get-VMNetworkAdapter -VMName $vm.Name).IPAddresses
    Write-Output ("{0}: {1}" -f $vm.Name, ($ips -join ", "))
}