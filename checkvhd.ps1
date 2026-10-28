$outFile = 'C:\Users\howar\AppData\Local\Temp\opencode\checkvhd_output.txt'
Remove-Item $outFile -ErrorAction SilentlyContinue
Stop-VM -Name BWANA-GOLDEN-SRC-03 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Mount-DiskImage -ImagePath "E:\BWANA\Hyper-V\BWANA-GOLDEN-SRC-03\BWANA-GOLDEN-SRC-03.vhdx" -Access ReadWrite
$diskImg = Get-DiskImage -ImagePath "E:\BWANA\Hyper-V\BWANA-GOLDEN-SRC-03\BWANA-GOLDEN-SRC-03.vhdx"
$disk = $diskImg | Get-Disk
$results = @()
$results += "=== Partitions ==="
Get-Partition -DiskNumber $disk.Number | ForEach-Object {
    $results += "  Part $($_.PartitionNumber): Type=$($_.Type), Size=$([math]::Round($_.Size/1MB))MB, Letter=$($_.DriveLetter)"
}
Dismount-DiskImage -ImagePath "E:\BWANA\Hyper-V\BWANA-GOLDEN-SRC-03\BWANA-GOLDEN-SRC-03.vhdx"
$results | Out-File -FilePath $outFile -Encoding UTF8
Write-Output "DONE"