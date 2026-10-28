$ErrorActionPreference = 'Continue'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'

Write-Host '=== disk images currently attached ==='
Get-DiskImage | Where-Object { $_.Attached } | Select-Object ImagePath, DevicePath | Format-Table -AutoSize

Write-Host '=== dismounting all attached images ==='
foreach ($img in (Get-DiskImage | Where-Object { $_.Attached })) {
    Write-Host "  Dismount: $($img.ImagePath)"
    Dismount-DiskImage -ImagePath $img.ImagePath -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 3

Write-Host '=== remount the target ISO and enumerate every resulting volume ==='
Mount-DiskImage -ImagePath $iso -Access ReadOnly | Out-Null
Start-Sleep -Seconds 4

$letters = @()
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5' | ForEach-Object {
    $letters += ($_.DeviceID + '\')
    Write-Host "  CDROM volume: $($_.DeviceID)  label='$($_.VolumeName)'  size=$([math]::Round($_.Size/1MB,1)) MB"
}

foreach ($l in $letters) {
    Write-Host ''
    Write-Host "--- probing $l ---"
    foreach ($probe in @('efi\boot\bootx64.efi','sources\boot.wim','setup.exe','sources\install.wim')) {
        $p = Join-Path $l $probe
        if (Test-Path -LiteralPath $p) {
            Write-Host ("  FOUND   {0}  ({1} bytes)" -f $probe, (Get-Item -LiteralPath $p).Length) -ForegroundColor Green
        }
        else {
            Write-Host ("  MISSING {0}" -f $probe) -ForegroundColor Yellow
        }
    }
    Write-Host '  root listing:'
    Get-ChildItem -LiteralPath $l -Force -ErrorAction SilentlyContinue | Select-Object -First 15 -ExpandProperty Name | ForEach-Object { Write-Host "    $_" }
}

Dismount-DiskImage -ImagePath $iso | Out-Null
Write-Host ''
Write-Host 'ISO dismounted'
