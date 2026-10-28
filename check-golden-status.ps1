$vmName = 'BWANA-GOLDEN-SRC'
$vm = Get-VM -Name $vmName
$vm | Select-Object Name, State, Uptime, Status, Heartbeat, MemoryAssigned, MemoryDemand, MemoryStartup, ProcessorUsage | Format-List

$vhdPath = 'C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx'
$vhd = Get-VHD -Path $vhdPath
$vhd | Select-Object Path, FileSize, Size, @{N='FileSizeGB';E={[math]::Round($_.FileSize/1GB,3)}}, @{N='SizeGB';E={[math]::Round($_.Size/1GB,3)}} | Format-List

# Check if integration services are responding by trying to get IP
$ip = Get-VMNetworkAdapter -VMName $vmName | Select-Object -ExpandProperty IPAddresses
"IPAddresses: $ip"
