$out = "C:\Users\howar\AppData\Local\Temp\opencode\elevated-test.log"
$whoami = whoami
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
"whoami: $whoami" | Out-File $out
"admin: $admin" | Out-File $out -Append
Get-Date | Out-File $out -Append
try {
    Mount-DiskImage -ImagePath 'C:\STEP\unattend\answer-GOLDEN.vhdx' -Access ReadOnly | Out-Null
    "mount: success" | Out-File $out -Append
    Dismount-DiskImage -ImagePath 'C:\STEP\unattend\answer-GOLDEN.vhdx' | Out-Null
    "dismount: success" | Out-File $out -Append
} catch {
    "mount error: $_" | Out-File $out -Append
}
