# diagnose leftover vhds/disks
Get-VHD C:\STEP\unattend\answer-DC01.vhdx -ErrorAction SilentlyContinue | Format-List Path,Attached | Out-String | Write-Output
Get-Disk | Format-Table Number,FriendlyName,PartitionStyle,OperationalStatus,Size | Out-String | Write-Output
Get-Command oscdimg.exe -ErrorAction SilentlyContinue | Format-Table Source | Out-String | Write-Output
Get-ChildItem 'C:\Program Files (x86)\Windows Kits\*\Assessment and Deployment Kit\Deployment Tools\*\Oscdimg\oscdimg.exe' -ErrorAction SilentlyContinue | Format-Table FullName | Out-String | Write-Output
Write-Output DONE-DIAG
