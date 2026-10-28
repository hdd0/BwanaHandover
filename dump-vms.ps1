foreach ($n in @('BWANA-DC01','BWANA-DC02','BWANA-GOLDEN-SRC','BWANA-NAS-01','BWANA-OKD-01','BWANA-OKD-02','BWANA-OKD-03','BWANA-OKD-BOOTSTRAP')) {
  Write-Output "===== $n ====="
  $vm = Get-VM -Name $n -ErrorAction SilentlyContinue
  if (-not $vm) { Write-Output 'NOT-FOUND'; continue }
  $vm | Select-Object Name,State,Generation,Path,AutomaticStartAction,AutomaticStopAction | Format-List | Out-String | Write-Output
  Get-VMFirmware -VMName $n | Select-Object SecureBoot,SecureBootTemplate,BootOrder | Format-List | Out-String | Write-Output
  Get-VMProcessor -VMName $n | Select-Object Count,CompatibilityForMigrationEnabled | Format-List | Out-String | Write-Output
  Get-VMMemory -VMName $n | Select-Object Startup,Minimum,Maximum,DynamicMemoryEnabled | Format-List | Out-String | Write-Output
  Get-VMNetworkAdapter -VMName $n | Select-Object Name,SwitchName,MacAddress,DynamicMacAddressEnabled | Format-List | Out-String | Write-Output
  Get-VMNetworkAdapterVlan -VMName $n | Format-List | Out-String | Write-Output
  Get-VMHardDiskDrive -VMName $n | Select-Object Path,ControllerType,ControllerNumber | Format-List | Out-String | Write-Output
  Get-VMDvdDrive -VMName $n | Select-Object Path,DvdMediaType,ControllerNumber | Format-List | Out-String | Write-Output
  Get-VMIntegrationService -VMName $n | Select-Object Name,Enabled | Format-Table -AutoSize | Out-String | Write-Output
}
