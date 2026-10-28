Get-VM | Format-Table Name,State,MemoryStartup,Path -AutoSize
Write-Output "---SWITCHES---"
Get-VMSwitch | Format-Table Name,SwitchType -AutoSize
Write-Output "---HOST VNIC IPS---"
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like 'vEthernet*' } | Format-Table InterfaceAlias,IPAddress,PrefixLength -AutoSize
Write-Output "---NATs---"
Get-NetNat -ErrorAction SilentlyContinue | Format-Table Name,InternalIPInterfaceAddressPrefix -AutoSize
Write-Output "---VMHost---"
Get-VMHost | Format-List VirtualHardDiskPath,VirtualMachinePath
