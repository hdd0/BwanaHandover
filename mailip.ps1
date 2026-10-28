Get-VMNetworkAdapter -VMName "BWANA-MAIL-01" | Select-Object VMName,SwitchName,MacAddress,IPAddresses,Status | Format-List
