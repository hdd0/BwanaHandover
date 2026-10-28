$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
Write-Output ("Admin=" + $admin)
whoami
Get-VMFirmware -VMName BWANA-DC01 | Format-List FirstBootDevice,BootOrder,SecureBoot,SecureBootTemplate | Out-String | Write-Output
Get-VMFirmware -VMName BWANA-DC02 | Format-List FirstBootDevice,BootOrder,SecureBoot,SecureBootTemplate | Out-String | Write-Output
