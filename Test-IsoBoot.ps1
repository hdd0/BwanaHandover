$ErrorActionPreference = 'Continue'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'

Write-Host "File size: $([math]::Round((Get-Item $iso).Length/1GB,2)) GB"
$hash = Get-FileHash -LiteralPath $iso -Algorithm SHA256
Write-Host "SHA256: $($hash.Hash)"

Mount-DiskImage -ImagePath $iso -Access ReadOnly | Out-Null
Start-Sleep -Seconds 3
$vol = Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5' | Select-Object -First 1
if (-not $vol) {
    $vol = Get-Volume | Where-Object { $_.DriveType -eq 'CDROM' -and $_.Size -gt 0 } | Select-Object -First 1
}
$root = if ($vol.PSObject.Properties.Name -contains 'DeviceID') { $vol.DeviceID + '\' } else { $vol.DriveLetter + ':\' }
Write-Host "Mounted at: $root"

foreach ($probe in @('efi\boot\bootx64.efi','sources\boot.wim','setup.exe','efi\microsoft\boot\bootmgfw.efi')) {
    $p = Join-Path $root $probe
    if (Test-Path -LiteralPath $p) {
        $len = (Get-Item -LiteralPath $p).Length
        Write-Host ("FOUND   {0}  ({1} bytes)" -f $probe, $len) -ForegroundColor Green
    }
    else {
        Write-Host ("MISSING {0}" -f $probe) -ForegroundColor Red
    }
}

Write-Host ''
Write-Host '--- images available in boot.wim ---'
try {
    $img = 'X:\sources\boot.wim'
    $letter = $root.Substring(0,2)
    $img = "$letter\sources\boot.wim"
    Get-WindowsImage -ImagePath $img | Select-Object ImageIndex, ImageName | Format-Table -AutoSize
}
catch { Write-Host "Get-WindowsImage failed: $($_.Exception.Message)" -ForegroundColor Yellow }

Dismount-DiskImage -ImagePath $iso | Out-Null
Write-Host 'ISO dismounted'
