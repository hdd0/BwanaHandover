$ErrorActionPreference = 'Continue'
Write-Output "=== POWERSHELL BITNESS ==="
Write-Output ("IntPtr size: {0} => {1}" -f [IntPtr]::Size, $(if ([IntPtr]::Size -eq 8) { '64-bit' } else { '32-bit (DISM will fail)' }))
Write-Output ("PSVersion: {0} | PSEdition: {1}" -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
Write-Output ("PS Path: {0}" -f (Get-Process -Id $PID).Path)
Write-Output ""
Write-Output "=== 64-bit DISM AVAILABLE? ==="
$dism64 = "$env:WINDIR\Sysnative\dism.exe"
Write-Output ("{0} exists: {1}" -f $dism64, (Test-Path $dism64))
Write-Output ""
Write-Output "=== ISO STILL MOUNTED? ==="
Get-Volume | Where-Object { $_.DriveLetter } | Select-Object DriveLetter, FileSystemLabel, DriveType | Format-Table -AutoSize
Write-Output ""
Write-Output "=== ANSWER DISK: find unattend.xml ==="
$ans = 'C:\STEP\unattend\answer-GOLDEN.vhdx'
Write-Output ("Answer VHD exists: {0} ({1} GB)" -f (Test-Path $ans), [math]::Round((Get-Item $ans).Length/1GB,2))
$mntAns = $false
try {
    Mount-VHD -Path $ans -ReadOnly -PassThru -ErrorAction Stop | Get-Disk | Get-Partition | Where-Object { $_.DriveLetter } | ForEach-Object {
        $L = $_.DriveLetter
        Write-Output "Answer volume mounted at ${L}:\"
        Get-ChildItem "${L}:\" -Recurse -Depth 2 -Include unattend.xml,*.xml -ErrorAction SilentlyContinue |
            Select-Object -First 10 FullName | ForEach-Object { Write-Output ("  FOUND: " + $_.FullName) }
    }
    $mntAns = $true
} catch { Write-Output "Answer VHD mount failed: $($_.Exception.Message)" }
finally { if ($mntAns) { try { Dismount-VHD -Path $ans; Write-Output "Answer VHD dismounted." } catch {} } }