$ErrorActionPreference='Stop'
Add-Type @"
using System;using System.Runtime.InteropServices;using System.Text;
public class NC {
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode)] public static extern bool CreateProcessW(string a,string c,IntPtr pa,IntPtr ia,bool inh,uint fl,IntPtr e,string d,ref STARTUPINFO si,out PROCESS_INFORMATION pi);
 [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);
 [StructLayout(LayoutKind.Sequential,CharSet=CharSet.Unicode)] public class STARTUPINFO { public int cb; public string lpReserved; public string lpDesktop; public string lpTitle; public int dwX,dwY,dwXSize,dwYSize,dwXCountChars,dwYCountChars,dwFillAttribute,dwFlags; public short wShowWindow,cbReserved2; public IntPtr lpReserved2,hStdInput,hStdOutput,hStdError; }
 [StructLayout(LayoutKind.Sequential)] public struct PROCESS_INFORMATION { public IntPtr hProcess,hThread; public int dwProcessId,dwThreadId; }
}
"@
$si=New-Object NC+STARTUPINFO; $si.cb=[Runtime.InteropServices.Marshal]::SizeOf($si); $si.dwFlags=1; $si.wShowWindow=5
$pi=New-Object NC+PROCESS_INFORMATION
$cmd = 'powershell.exe -NoExit -NoProfile -Command "Set-Location C:\STEP; opencode"'
[NC]::CreateProcessW($null,$cmd,[IntPtr]::Zero,[IntPtr]::Zero,$false,0x10,[IntPtr]::Zero,'C:\STEP',[ref]$si,[ref]$pi) | Out-Null
"created pid=$($pi.dwProcessId)"
[NC]::CloseHandle($pi.hProcess) | Out-Null; [NC]::CloseHandle($pi.hThread) | Out-Null
