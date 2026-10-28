$ErrorActionPreference = 'Continue'
Write-Host "--- All VM states ---"
Get-VM | Where-Object { $_.Name -like 'BWANA-*' -or $_.Name -eq 'DockerDesktopVM' } |
    Select-Object Name,State,Generation,@{n='Uptime_s';e={$_.Uptime}} | Format-Table -AutoSize

Write-Host ""
Write-Host "--- DC01 has same DVD ISO? ---"
Get-VM -Name BWANA-DC01 | Get-VMDvdDrive | Select-Object Path,ControllerType | Format-List
Get-VM -Name BWANA-DC01 | Get-VMHardDiskDrive | Select-Object Path | Format-List
