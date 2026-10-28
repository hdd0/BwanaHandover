$vms = @('BWANA-DC01', 'BWANA-DC02')
foreach ($vmName in $vms) {
    $vm = Get-VM -Name $vmName
    if ($vm.State -eq 'Off') {
        "Starting $vmName"
        Start-VM -Name $vmName
    } else {
        "$vmName is $($vm.State)"
    }
}

Start-Sleep -Seconds 10
foreach ($vmName in $vms) {
    $vm = Get-VM -Name $vmName
    "$vmName : $($vm.State) | Uptime: $($vm.Uptime) | Heartbeat: $($vm.Heartbeat)"
}
