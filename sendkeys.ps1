param([string]$Keys)
Add-Type @"
using System;using System.Runtime.InteropServices;
public class SK {
 [DllImport("user32.dll")] public static extern void keybd_event(byte k,byte s,uint f,IntPtr e);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
function Tap([int]$vk){
  [SK]::keybd_event([byte]$vk,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 40
  [SK]::keybd_event([byte]$vk,0,2,[IntPtr]::Zero); Start-Sleep -Milliseconds 40
}
$h=[IntPtr]6884714
[SK]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 800
foreach($ch in $Keys.ToCharArray()){
  if($ch -eq '{'){ Tap 0xDB }
  elseif($ch -eq '}'){ Tap 0xDC }
  elseif($ch -eq '/'){ Tap 0xBF }
  elseif($ch -match '[A-Z]'){ [SK]::keybd_event(0x10,0,0,[IntPtr]::Zero); Start-Sleep -Milliseconds 40; Tap([int][char]$ch); [SK]::keybd_event(0x10,0,2,[IntPtr]::Zero); Start-Sleep -Milliseconds 40 }
  else { Tap([int][char]$ch) }
}
"typed: $Keys"
