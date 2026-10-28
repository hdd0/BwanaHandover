$vm = Get-VM -Name 'BWANA-GOLDEN-SRC'
$vm | Select-Object Name, State, Uptime, Status, PrimaryOperationalStatus, Heartbeat, IntegrationServicesVersion, ComputerName, IPAddresses | Format-List

"--- Firmware ---"
Get-VMFirmware -VMName 'BWANA-GOLDEN-SRC' | Select-Object BootOrder, SecureBoot, SecureBootTemplate, PreferredNetworkBootProtocol | Format-List

"--- Hard Drives ---"
$vm.HardDrives | Select-Object Name, Path, ControllerType, ControllerNumber, ControllerLocation, PoolName | Format-List

"--- DVD Drives ---"
$vm.DVDDrives | Select-Object Name, Path, ControllerType, ControllerNumber, ControllerLocation | Format-List

"--- Network Adapters ---"
Get-VMNetworkAdapter -VMName 'BWANA-GOLDEN-SRC' | Select-Object Name, IPAddresses, MacAddress, SwitchName, IsLegacy | Format-List

"--- VHD Details ---"
foreach ($hd in $vm.HardDrives) { Get-VHD -Path $hd.Path | Select-Object Path, VhdFormat, VhdType, FileSize, Size, @{N='FileSizeGB';E={[math]::Round($_.FileSize/1GB,3)}}, @{N='SizeGB';E={[math]::Round($_.Size/1GB,3)}} | Format-List }
