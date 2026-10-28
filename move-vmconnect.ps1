Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinApi {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint pid);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    public static readonly IntPtr HWND_TOP = IntPtr.Zero;
    public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const uint SWP_FRAMECHANGED = 0x0020;
}
"@

$screens = [System.Windows.Forms.Screen]::AllScreens
$target = $screens | Where-Object { -not $_.Primary } | Sort-Object { $_.Bounds.Width * $_.Bounds.Height } -Descending | Select-Object -First 1
if (-not $target) { $target = $screens[0] }
$b = $target.Bounds
"Target display: $($target.DeviceName) $($b.Width)x$($b.Height) at $($b.X),$($b.Y)"

$p = Get-Process -Name 'vmconnect' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $p) { "vmconnect not running"; exit 1 }
"vmconnect PID: $($p.Id)"

$found = $null
$cb = [WinApi+EnumWindowsProc] {
    param($hWnd, $lParam)
    if ([WinApi]::IsWindowVisible($hWnd)) {
        $pid = 0
        [void][WinApi]::GetWindowThreadProcessId($hWnd, [ref]$pid)
        if ($pid -eq $script:pId) {
            $len = [WinApi]::GetWindowTextLength($hWnd)
            $sb = New-Object System.Text.StringBuilder ($len + 1)
            [void][WinApi]::GetWindowText($hWnd, $sb, $len + 1)
            $script:found = @{ hWnd=$hWnd; title=$sb.ToString() }
            return $false
        }
    }
    return $true
}
$script:pId = $p.Id
[void][WinApi]::EnumWindows($cb, [IntPtr]::Zero)

if (-not $found) { "No visible vmconnect window found"; exit 1 }
"Window: $($found.title)"

# Move to target display, restore if minimized is not handled here
[void][WinApi]::SetWindowPos($found.hWnd, [WinApi]::HWND_TOP, $b.X + 50, $b.Y + 50, 1280, 800, [WinApi]::SWP_SHOWWINDOW -bor [WinApi]::SWP_FRAMECHANGED)
"Moved vmconnect to $($target.DeviceName)"
