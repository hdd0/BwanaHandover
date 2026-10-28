Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinApi3 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    public static readonly IntPtr HWND_TOP = IntPtr.Zero;
    public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const uint SWP_FRAMECHANGED = 0x0020;
    public const int SW_RESTORE = 9;
    public const int SW_MAXIMIZE = 3;
}
"@

$proc = Get-Process -Name 'vmconnect' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) {
    "vmconnect not running"
    exit 1
}

$foundHwnd = [IntPtr]::Zero
$cb = [WinApi3+EnumWindowsProc] {
    param($hWnd, $lParam)
    if ([WinApi3]::IsWindowVisible($hWnd)) {
        $procId = 0
        [void][WinApi3]::GetWindowThreadProcessId($hWnd, [ref]$procId)
        if ($procId -eq $script:targetPid) {
            $script:foundHwnd = $hWnd
            return $false
        }
    }
    return $true
}
$script:targetPid = $proc.Id
[void][WinApi3]::EnumWindows($cb, [IntPtr]::Zero)

if ($script:foundHwnd -eq [IntPtr]::Zero) {
    "No visible vmconnect window"
    exit 1
}

[void][WinApi3]::ShowWindow($script:foundHwnd, [WinApi3]::SW_MAXIMIZE)
[void][WinApi3]::SetForegroundWindow($script:foundHwnd)
Start-Sleep -Milliseconds 500

$r = New-Object WinApi3+RECT
[void][WinApi3]::GetWindowRect($script:foundHwnd, [ref]$r)
$w = $r.Right - $r.Left
$h = $r.Bottom - $r.Top
"Window rect: $($r.Left),$($r.Top) $($w)x$h"

$shotsDir = 'C:\STEP\BwanaAI\BwanaAI\dev\screenshots'
New-Item -ItemType Directory -Path $shotsDir -Force | Out-Null
$path = Join-Path $shotsDir ("vmconnect-{0}.png" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$bmp = New-Object System.Drawing.Bitmap($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen([System.Drawing.Point]::new($r.Left, $r.Top), [System.Drawing.Point]::Empty, [System.Drawing.Size]::new($w, $h))
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
"Saved: $path"
