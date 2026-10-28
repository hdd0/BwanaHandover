$vms = @('BWANA-DC01', 'BWANA-DC02', 'BWANA-GOLDEN-SRC')
foreach ($vmName in $vms) {
    $vm = Get-VM -Name $vmName
    $ip = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
    [pscustomobject]@{
        Name = $vmName
        State = $vm.State
        Uptime = $vm.Uptime
        Heartbeat = $vm.Heartbeat
        IPAddresses = ($ip -join ', ')
    }
}
