Add-Type @"
using System;using System.Runtime.InteropServices;
public class MC {
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,int dx,int dy,uint d,IntPtr e);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
# DISPLAY3 origin is -1920,360 ; "Skip" button in screenshot-local px ~ (730,403)
$sx = 730 - 1920
$sy = 403 + 360
[MC]::SetForegroundWindow([IntPtr]16256042) | Out-Null
Start-Sleep -Milliseconds 600
[MC]::SetCursorPos($sx,$sy) | Out-Null
Start-Sleep -Milliseconds 400
[MC]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero)   # LEFTDOWN
Start-Sleep -Milliseconds 80
[MC]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)   # LEFTUP
"clicked at screen ($sx,$sy)"
