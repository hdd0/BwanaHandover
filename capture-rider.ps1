Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing @"
using System;using System.Text;using System.Runtime.InteropServices;using System.Collections.Generic;using System.Drawing;using System.Drawing.Imaging;
public class RC {
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p,IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h,StringBuilder s,int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h,IntPtr a,int x,int y,int w,int f,uint fl);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
 public delegate bool EnumProc(IntPtr h,IntPtr l);

 public static IntPtr FindWindowByTitle(string needle){
  IntPtr found=IntPtr.Zero;
  EnumWindows((h,l)=>{ if(!IsWindowVisible(h)) return true;
    var sb=new StringBuilder(512); GetWindowText(h,sb,512);
    if(sb.ToString().Contains(needle)){ found=h; return false; }
    return true; },IntPtr.Zero);
  return found;
 }
 public static string Capture(string needle,string outPath,int x,int y,int w,int h){
  IntPtr wnd=FindWindowByTitle(needle);
  if(wnd==IntPtr.Zero) return "WINDOW NOT FOUND: "+needle;
  ShowWindow(wnd,9);
  SetWindowPos(wnd,new IntPtr(-1),x,y,w,h,0x0040);
  SetForegroundWindow(wnd);
  System.Threading.Thread.Sleep(4000);
  RECT rc; GetWindowRect(wnd,out rc);
  int ww=rc.R-rc.L, wh=rc.B-rc.T;
  if(ww<=0||wh<=0) return "BAD RECT";
  using(var bmp=new Bitmap(ww,wh)){
    using(var g=Graphics.FromImage(bmp)){
      IntPtr dc=g.GetHdc();
      bool ok=PrintWindow(wnd,dc,2);   // 2 = PW_RENDERFULLCONTENT
      g.ReleaseHdc(dc);
      if(!ok) return "PRINTWINDOW FAILED";
    }
    bmp.Save(outPath,ImageFormat.Png);
  }
  return "SAVED "+outPath+" size="+ww+"x"+wh+" title="+needle;
 }
}
"@
[RC]::Capture("BwanaPlatform","$env:USERPROFILE\.config\opencode\dev\rider-tab-test.png",-1900,420,1500,700)
