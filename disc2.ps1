$p = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
Write-Output ("IsAdmin=" + $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
Write-Output ("PS=" + $PSVersionTable.PSVersion)
Get-VMSwitch | Format-Table Name, SwitchType -AutoSize
Get-NetNat -ErrorAction SilentlyContinue | Format-Table Name, InternalIPInterfaceAddressPrefix -AutoSize
