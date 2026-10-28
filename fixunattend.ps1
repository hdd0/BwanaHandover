$outFile = 'C:\Users\howar\AppData\Local\Temp\opencode\fixunattend_output.txt'
Remove-Item $outFile -ErrorAction SilentlyContinue
Stop-VM -Name BWANA-GOLDEN-SRC -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
Mount-DiskImage -ImagePath "C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx" -Access ReadWrite
$diskImg = Get-DiskImage -ImagePath "C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx"
$disk = $diskImg | Get-Disk
$winPart = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.Type -eq 'Basic' } | Select-Object -First 1
$winPart | Set-Partition -NewDriveLetter W
# Copy fixed unattend
$pantherDir = 'W:\Windows\Panther\Unattend'
New-Item -ItemType Directory -Path $pantherDir -Force | Out-Null
Copy-Item -Path 'C:\STEP\BwanaMail\data\Unattend.xml' -Destination "$pantherDir\Unattend.xml" -Force
$results = @()
if (Test-Path "$pantherDir\Unattend.xml") {
    $results += "Unattend copied successfully"
    # Validate XML
    try {
        [xml]$xml = Get-Content "$pantherDir\Unattend.xml"
        $results += "XML is valid"
    } catch {
        $results += "XML validation failed: $($_.Exception.Message)"
    }
} else {
    $results += "FAILED to copy unattend"
}
$winPart | Remove-PartitionAccessPath -AccessPath 'W:\' -ErrorAction SilentlyContinue
Dismount-DiskImage -ImagePath "C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx"
$results | Out-File -FilePath $outFile -Encoding UTF8
Write-Output "DONE"