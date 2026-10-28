$answerDisk = 'C:\STEP\unattend\answer-GOLDEN.vhdx'
"Mounting $answerDisk"
Mount-DiskImage -ImagePath $answerDisk -Access ReadOnly | Out-Null
$vol = Get-DiskImage -ImagePath $answerDisk | Get-Disk | Get-Partition | Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
if ($vol) {
    $drive = "$($vol.DriveLetter):"
    "Drive letter: $drive"
    Get-ChildItem $drive -Recurse | Select-Object FullName, Length | Format-Table -AutoSize
} else {
    "No drive letter found"
}
Dismount-DiskImage -ImagePath $answerDisk | Out-Null
"Done"
