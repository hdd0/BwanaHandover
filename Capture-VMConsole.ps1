# Force a VMConnect window to the top of the chosen display (bypasses the
# Windows foreground lock that kept MobaXterm on top) and screenshot it.
param(
    [Parameter(Mandatory = $true)][int]$ProcessId,
    [Parameter(Mandatory = $true)][string]$CapturePath,
    [int]$DisplayIndex = -1,
    [int]$SettleSeconds = 3
)

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class Win32Top {
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int X, int Y, int cx, int cy, uint flags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int cmd);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@

$HWND_TOPMOST    = [IntPtr](-1)
$HWND_NOTOPMOST = [IntPtr](-2)
$SWP_SHOWWINDOW  = 0x0040

function Get-TargetScreen {
    $screens = @([System.Windows.Forms.Screen]::AllScreens)
    if ($DisplayIndex -ge 0 -and $DisplayIndex -lt $screens.Count) { return $screens[$DisplayIndex] }
    $nonPrimary = @($screens | Where-Object { -not $_.Primary })
    if ($nonPrimary.Count -gt 0) { return ($nonPrimary | Sort-Object { $_.Bounds.Width * $_.Bounds.Height } -Descending | Select-Object -First 1) }
    return $screens[0]
}

$screen = Get-TargetScreen
$b = $screen.Bounds
$p = Get-Process -Id $ProcessId -ErrorAction Stop
$p.Refresh()
Write-Host "Target: $($p.MainWindowTitle)"

[void][Win32Top]::ShowWindow($p.MainWindowHandle, 9)
Start-Sleep -Milliseconds 500
[void][Win32Top]::SetWindowPos($p.MainWindowHandle, $HWND_TOPMOST, $b.X, $b.Y, $b.Width, $b.Height, $SWP_SHOWWINDOW)
Start-Sleep -Seconds 1
[void][Win32Top]::SetForegroundWindow($p.MainWindowHandle)
Start-Sleep -Seconds $SettleSeconds

$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.CopyFromScreen($b.X, $b.Y, 0, 0, $bmp.Size)
$gfx.Dispose()
New-Item -ItemType Directory -Path (Split-Path -Parent $CapturePath) -Force | Out-Null
$bmp.Save($CapturePath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

# Drop back to normal z-order so the console does not sit above everything.
[void][Win32Top]::SetWindowPos($p.MainWindowHandle, $HWND_NOTOPMOST, $b.X, $b.Y, $b.Width, $b.Height, $SWP_SHOWWINDOW)

Write-Host "Saved: $CapturePath ($([math]::Round((Get-Item $CapturePath).Length/1KB)) KB)"
