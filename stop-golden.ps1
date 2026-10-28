$vmName = 'BWANA-GOLDEN-SRC'
$vm = Get-VM -Name $vmName
if ($vm.State -ne 'Off') {
    Stop-VM -Name $vmName -Force -ErrorAction Stop
}
Get-VM -Name $vmName | Select-Object Name, State, Uptime | Format-List
