$log = 'C:\Users\howar\AppData\Local\Temp\opencode\test-format.log'
Start-Transcript -Path $log -Force | Out-Null
$vhdPath = 'C:\Users\howar\AppData\Local\Temp\opencode\testfmt.vhdx'
New-VHD -Path $vhdPath -SizeBytes 1GB -Dynamic | Out-Null
Mount-DiskImage -ImagePath $vhdPath -Access ReadWrite | Out-Null
$disk = Get-DiskImage -ImagePath $vhdPath | Get-Disk
Initialize-Disk -Number $disk.Number -PartitionStyle GPT
$part = New-Partition -DiskNumber $disk.Number -Size 260MB
"Partition created: $($part.PartitionNumber)"
try {
    $part | Set-Partition -NewDriveLetter T | Out-Null
    $fmt = Format-Volume -DriveLetter T -FileSystem NTFS -NewFileSystemLabel TEST -Confirm:$false
    "Format succeeded: $($fmt.FileSystemLabel)"
} catch {
    "Format failed: $_"
}
Dismount-DiskImage -ImagePath $vhdPath | Out-Null
Remove-Item $vhdPath -Force
Stop-Transcript | Out-Null
