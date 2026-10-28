$log = 'C:\Users\howar\AppData\Local\Temp\opencode\answer-disk-contents3.log'
Start-Transcript -Path $log -Force | Out-Null
$answerDisk = 'C:\STEP\unattend\answer-GOLDEN.vhdx'
Mount-DiskImage -ImagePath $answerDisk -Access ReadOnly | Out-Null
$disk = Get-DiskImage -ImagePath $answerDisk | Get-Disk
"Disk number: $($disk.Number), OperationalStatus: $($disk.OperationalStatus)"
Set-Disk -Number $disk.Number -IsOffline $false
"Brought online"
$part = $disk | Get-Partition | Select-Object -First 1
"Partition: $($part.PartitionNumber), Type: $($part.Type), DriveLetter: $($part.DriveLetter)"
if (-not $part.DriveLetter) {
    $part | Set-Partition -NewDriveLetter Z | Out-Null
    $part = Get-Partition -DiskNumber $disk.Number -PartitionNumber $part.PartitionNumber
}
$drive = "$($part.DriveLetter):"
"Drive letter: $drive"
Get-ChildItem $drive -Recurse | Select-Object FullName, Length | Format-Table -AutoSize

# Copy contents to staging
$stage = 'C:\STEP\BwanaMail\data\answer-disk-staging'
New-Item -ItemType Directory -Path $stage -Force | Out-Null
Copy-Item -Path "$drive\*" -Destination $stage -Recurse -Force
"Copied to $stage"
Get-ChildItem $stage -Recurse | Select-Object FullName, Length | Format-Table -AutoSize

Dismount-DiskImage -ImagePath $answerDisk | Out-Null
Stop-Transcript | Out-Null
