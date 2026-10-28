$log = 'C:\Users\howar\AppData\Local\Temp\opencode\answer-disk-contents.log'
Start-Transcript -Path $log -Force | Out-Null
$answerDisk = 'C:\STEP\unattend\answer-GOLDEN.vhdx'
Mount-DiskImage -ImagePath $answerDisk -Access ReadOnly | Out-Null
$vol = Get-DiskImage -ImagePath $answerDisk | Get-Disk | Get-Partition | Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
if ($vol) {
    $drive = "$($vol.DriveLetter):"
    "Drive letter: $drive"
    Get-ChildItem $drive -Recurse | Select-Object FullName, Length | Format-Table -AutoSize
} else {
    "No drive letter found"
    $disk = Get-DiskImage -ImagePath $answerDisk | Get-Disk
    $disk | Get-Partition | Select-Object * | Format-Table -AutoSize
}
Dismount-DiskImage -ImagePath $answerDisk | Out-Null
Stop-Transcript | Out-Null
