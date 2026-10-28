$ErrorActionPreference = 'Continue'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'

Write-Host '=== Dismounting every stale CDROM volume (repeat until clear) ==='
for ($i = 1; $i -le 12; $i++) {
    $vols = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5')
    if ($vols.Count -eq 0) { Write-Host "Pass $i`: no CDROM volumes remain."; break }
    Write-Host "Pass $i`: $($vols.Count) CDROM volume(s) -> $($vols.DeviceID -join ',')"
    Dismount-DiskImage -ImagePath $iso -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}
Write-Host "Final CDROM volume count: $((Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=5').Count)"
