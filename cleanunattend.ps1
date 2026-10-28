$outFile = 'C:\Users\howar\AppData\Local\Temp\opencode\checkvhd_output.txt'
Remove-Item $outFile -ErrorAction SilentlyContinue
Stop-VM -Name BWANA-GOLDEN-SRC -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Mount-DiskImage -ImagePath "C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx" -Access ReadWrite
$diskImg = Get-DiskImage -ImagePath "C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx"
$disk = $diskImg | Get-Disk
$winPart = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.Type -eq 'Basic' } | Select-Object -First 1
$winPart | Set-Partition -NewDriveLetter W
$results = @()
# Remove ALL unattend files
Remove-Item 'W:\Windows\Panther\Unattend\*' -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item 'W:\Windows\System32\Sysprep\Unattend.xml' -Force -ErrorAction SilentlyContinue
Remove-Item 'W:\Windows\Panther\UnattendGC\*' -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item 'W:\goldendisk' -Force -Recurse -ErrorAction SilentlyContinue
$results += "Removed all unattend files and goldendisk"
# Disable AutoAdminLogon in registry
reg load HKLM\OFFLINE 'W:\Windows\System32\config\SOFTWARE' 2>&1 | Out-Null
reg add 'HKLM\OFFLINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v AutoAdminLogon /t REG_SZ /d 0 /f 2>&1 | Out-Null
reg unload HKLM\OFFLINE 2>&1 | Out-Null
$results += "Disabled AutoAdminLogon"
$winPart | Remove-PartitionAccessPath -AccessPath 'W:\' -ErrorAction SilentlyContinue
Dismount-DiskImage -ImagePath "C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx"
$results | Out-File -FilePath $outFile -Encoding UTF8
Write-Output "DONE"