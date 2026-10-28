# iso inspect: mount, list images, dismount
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
Mount-DiskImage -ImagePath $iso | Out-Null
$vol = (Get-DiskImage -ImagePath $iso | Get-Volume)
$drive = ($vol.DriveLetter + ':')
Write-Output ("drive=" + $drive)
Get-ChildItem ($drive + '\sources\install.*') | Format-Table Name,Length | Out-String | Write-Output
$wim = Get-ChildItem ($drive + '\sources\install.*') | Select-Object -First 1 -ExpandProperty FullName
dism /Get-WimInfo /WimFile:$wim 2>&1 | Select-Object -First 30 | Write-Output
Dismount-DiskImage -ImagePath $iso | Out-Null
Write-Output "---VLAN---"
Get-VMNetworkAdapterVlan -VMName BWANA-DC01 | Format-List | Out-String | Write-Output
Get-VMNetworkAdapterVlan -VMName BWANA-DC02 | Format-List | Out-String | Write-Output
Write-Output DONE-ISO
