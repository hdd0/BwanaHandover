# Capture a specific window's content with PrintWindow, independent of z-order.
param(
    [Parameter(Mandatory = $true)][int]$ProcessId,
    [Parameter(Mandatory = $true)][string]$CapturePath
)

$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
public class WinCap {
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    public static Bitmap Capture(IntPtr hWnd) {
        RECT r;
        if (!GetWindowRect(hWnd, out r)) return null;
        int w = r.Right - r.Left, h = r.Bottom - r.Top;
        if (w <= 0 || h <= 0) return null;
        Bitmap bmp = new Bitmap(w, h);
        using (Graphics g = Graphics.FromImage(bmp)) {
            IntPtr hdc = g.GetHdc();
            // 0x2 = PW_RENDERFULLCONTENT, captures even if occluded.
            PrintWindow(hWnd, hdc, 0x2);
            g.ReleaseHdc(hdc);
        }
        return bmp;
    }
}
'@ -ReferencedAssemblies System.Drawing

$p = Get-Process -Id $ProcessId -ErrorAction Stop
$p.Refresh()
if ($p.MainWindowHandle -eq 0) { Write-Host 'Process has no main window.'; exit 1 }
Write-Host "Capturing PID=$ProcessId Title='$($p.MainWindowTitle)'"

$bmp = [WinCap]::Capture($p.MainWindowHandle)
if ($null -eq $bmp) { Write-Host 'PrintWindow returned no image.' -ForegroundColor Red; exit 1 }

New-Item -ItemType Directory -Path (Split-Path -Parent $CapturePath) -Force | Out-Null
$bmp.Save($CapturePath, [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Saved: $CapturePath ($($bmp.Width)x$($bmp.Height), $([math]::Round((Get-Item $CapturePath).Length/1KB)) KB)"
$bmp.Dispose()
