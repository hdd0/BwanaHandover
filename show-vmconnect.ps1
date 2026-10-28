Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinApi2 {
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

$screens = [System.Windows.Forms.Screen]::AllScreens
$target = $screens | Where-Object { -not $_.Primary } | Sort-Object { $_.Bounds.Width * $_.Bounds.Height } -Descending | Select-Object -First 1
if (-not $target) { $target = $screens[0] }
$b = $target.Bounds
"Target display: $($target.DeviceName) $($b.Width)x$($b.Height) at $($b.X),$($b.Y)"

$proc = Get-Process -Name 'vmconnect' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $proc) {
    "vmconnect not running, launching new instance"
    $proc = Start-Process 'C:\Windows\System32\vmconnect.exe' -ArgumentList 'localhost','BWANA-GOLDEN-SRC' -PassThru
    Start-Sleep -Seconds 2
}
"vmconnect PID: $($proc.Id)"

$foundHwnd = [IntPtr]::Zero
$cb = [WinApi2+EnumWindowsProc] {
    param($hWnd, $lParam)
    if ([WinApi2]::IsWindowVisible($hWnd)) {
        $procId = 0
        [void][WinApi2]::GetWindowThreadProcessId($hWnd, [ref]$procId)
        if ($procId -eq $script:targetPid) {
            $len = [WinApi2]::GetWindowTextLength($hWnd)
            $sb = New-Object System.Text.StringBuilder ($len + 1)
            [void][WinApi2]::GetWindowText($hWnd, $sb, $len + 1)
            $script:foundTitle = $sb.ToString()
            $script:foundHwnd = $hWnd
            return $false
        }
    }
    return $true
}
$script:targetPid = $proc.Id
$script:foundTitle = ''
[void][WinApi2]::EnumWindows($cb, [IntPtr]::Zero)

if ($script:foundHwnd -eq [IntPtr]::Zero) {
    "No visible vmconnect window found"
    exit 1
}
"Window: $script:foundTitle"

[void][WinApi2]::ShowWindow($script:foundHwnd, [WinApi2]::SW_RESTORE)
[void][WinApi2]::SetForegroundWindow($script:foundHwnd)
$w = [Math]::Min(1280, $b.Width - 100)
$h = [Math]::Min(800, $b.Height - 100)
[void][WinApi2]::SetWindowPos($script:foundHwnd, [WinApi2]::HWND_TOP, $b.X + 50, $b.Y + 50, $w, $h, [WinApi2]::SWP_SHOWWINDOW -bor [WinApi2]::SWP_FRAMECHANGED)
"Restored and moved vmconnect to $($target.DeviceName)"
