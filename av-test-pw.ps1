Add-Type -TypeDefinition @"
using System; using System.Drawing; using System.Runtime.InteropServices;
public class C2 { [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr d, uint f); }
"@ -ReferencedAssemblies System.Drawing
Write-Host 'printwindow OK'
