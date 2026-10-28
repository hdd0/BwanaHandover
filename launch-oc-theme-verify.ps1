$ErrorActionPreference='Stop'
$dx=-1920; $dy=360; $dw=1000; $dh=640
$px=$dx + [int]($dw/3); $py=$dy + 120
$exe=(Get-Command opencode).Source
$log="$env:USERPROFILE\.config\opencode\dev\theme-verify.log"
New-Item -ItemType Directory -Force -Path (Split-Path $log) | Out-Null
$cmd = "Set-Location C:\STEP; & '$exe' *>&1 | Tee-Object -FilePath '$log'"
$p = Start-Process powershell.exe -ArgumentList @('-NoExit','-NoProfile','-Command',$cmd) -PassThru
Start-Sleep -Seconds 3
Add-Type @"
using System;using System.Runtime.InteropServices;
public class W {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h,int x,int y,int w,int t,bool r);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
}
"@
$h=$p.MainWindowHandle
[W]::ShowWindow($h,9) | Out-Null
[W]::MoveWindow($h,$px,$py,$dw,$dh,$true) | Out-Null
[W]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Seconds 6
"PID=$($p.Id)  H=$h  LOG=$log"
