# discovery for unattended: VM config + ISO images + resources
Write-Output "---VM DC01---"
Get-VM BWANA-DC01 | Format-List Name,State,Generation,MemoryStartup,ProcessorCount,Path | Out-String | Write-Output
Get-VMFirmware BWANA-DC01 | Format-List SecureBoot,SecureBootTemplate | Out-String | Write-Output
Get-VMDvdDrive -VMName BWANA-DC01 | Format-Table ControllerNumber,Path | Out-String | Write-Output
Get-VMHardDiskDrive -VMName BWANA-DC01 | Format-Table Path | Out-String | Write-Output
Get-VMNetworkAdapter -VMName BWANA-DC01 | Format-Table SwitchName,VlanId | Out-String | Write-Output
Write-Output "---VM DC02---"
Get-VM BWANA-DC02 | Format-List Name,State,Generation,MemoryStartup,ProcessorCount,Path | Out-String | Write-Output
Get-VMDvdDrive -VMName BWANA-DC02 | Format-Table ControllerNumber,Path | Out-String | Write-Output
Write-Output "---ISO images---"
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
$vol = Get-DiskImage -ImagePath $iso | Get-Volume
Write-Output ("mounted=" + ($vol -ne $null))
dism /Get-WimInfo /WimFile:E:\sources\install.wim 2>&1 | Select-Object -First 40 | Write-Output
Write-Output "---host disk---"
Get-PSDrive C | Format-Table Name,@{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}} -AutoSize | Out-String | Write-Output
Write-Output DONE-DISCOVERY
