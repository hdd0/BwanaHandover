$ErrorActionPreference = 'Stop'
# Standalone proof that an unattended answer ISO can be produced without elevation.
$staging = Join-Path $env:TEMP 'bwana-isotest'
$isoOut  = Join-Path $env:TEMP 'bwana-answer-isotest.iso'
Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $isoOut  -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $staging -Force | Out-Null
Copy-Item -LiteralPath 'C:\STEP\BwanaMail\data\BWANA-MAIL-01-Autounattend.xml' -Destination (Join-Path $staging 'Autounattend.xml') -Force

$image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage -Property @{ VolumeName = 'AUTOUNATTEND' }
$image.FileSystemsToCreate = 3
[void]$image.Root.AddTree($staging, $false)

$isoStream = $image.GetResult()
$buffer = New-Object byte[] 1048576
$memory = New-Object System.IO.MemoryStream
while ($true) {
    $read = $isoStream.Read($buffer, $buffer.Length)
    if ($read -le 0) { break }
    $memory.Write($buffer, 0, $read)
}
[System.IO.File]::WriteAllBytes($isoOut, $memory.ToArray())
$memory.Dispose()

Write-Host "ISO written: $isoOut ($((Get-Item $isoOut).Length) bytes)"

# Prove it mounts and the answer file is readable from the ISO root.
Mount-DiskImage -ImagePath $isoOut -Access ReadOnly | Out-Null
Start-Sleep -Seconds 2
$drive = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -like '*\ISO*' } | Select-Object -First 1
if (-not $drive) { $drive = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | Where-Object { $_.VolumeName -eq 'AUTOUNATTEND' } | ForEach-Object { $_.DeviceID + '\' } | Select-Object -First 1 }
Write-Host "Mounted drive: $drive"
$found = Get-ChildItem "$drive*" -Filter 'Autounattend.xml' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($found) {
    Write-Host "PASS: Autounattend.xml visible on answer ISO at $($found.FullName)"
    $xml = [xml](Get-Content -LiteralPath $found.FullName -Raw)
    $cn = $xml.SelectNodes("//*[local-name()='ComputerName']")[0].InnerText
    $auto = $xml.SelectNodes("//*[local-name()='AutoLogon']/*[local-name()='Enabled']")[0].InnerText
    Write-Host "  ComputerName = $cn"
    Write-Host "  AutoLogon Enabled = $auto"
} else {
    Write-Host 'FAIL: Autounattend.xml not found on the generated ISO.'
}
Dismount-DiskImage -ImagePath $isoOut | Out-Null
Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
