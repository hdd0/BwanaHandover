Add-Type @'
using System;using System.Text;using System.Runtime.InteropServices;using System.Collections.Generic;
public class TU {
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p,IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,int x,int y,uint d,IntPtr e);
 public delegate bool EnumProc(IntPtr h,IntPtr l);
 public static IntPtr Find(string needle){
  IntPtr found=IntPtr.Zero;
  EnumWindows((h,l)=>{ if(!IsWindowVisible(h)) return true;
    var sb=new StringBuilder(512); GetWindowText(h,sb,512);
    if(sb.ToString().Contains(needle)){ found=h; return false; }
    return true; },IntPtr.Zero);
  return found;
 }
 public static string Click(string needle,int x,int y){
  IntPtr w=Find(needle);
  if(w==IntPtr.Zero) return "NOT FOUND: "+needle;
  SetForegroundWindow(w);
  System.Threading.Thread.Sleep(1200);
  SetCursorPos(x,y);
  System.Threading.Thread.Sleep(600);
  mouse_event(0x0002,0,0,0,IntPtr.Zero);   // LEFTDOWN
  System.Threading.Thread.Sleep(120);
  mouse_event(0x0004,0,0,0,IntPtr.Zero);   // LEFTUP
  return "CLICKED "+needle+" at "+x+","+y;
 }
}
'@
# window sits at -1900,420 size 1500x700; "Trust and Open" is at local (1302,661)
[TU]::Click("Untrusted Solution",-598,1081)
