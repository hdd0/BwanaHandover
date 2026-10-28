$ErrorActionPreference = 'Continue'
$vm = 'BWANA-MAIL-01'

Write-Host '=== Current firmware ==='
Get-VMFirmware -VMName $vm | Select-Object SecureBoot, SecureBootTemplate | Format-List

Write-Host '=== Stopping VM ==='
if ((Get-VM -Name $vm).State -ne 'Off') {
    Stop-VM -Name $vm -Force
    while ((Get-VM -Name $vm).State -ne 'Off') { Start-Sleep -Seconds 2 }
}
Write-Host "State: $((Get-VM -Name $vm).State)"

Write-Host '=== Disabling Secure Boot for the install phase ==='
Set-VMFirmware -VMName $vm -EnableSecureBoot Off -SecureBootTemplate MicrosoftWindows
Get-VMFirmware -VMName $vm | Select-Object SecureBoot, SecureBootTemplate | Format-List

Write-Host '=== DVD / boot order ==='
Get-VMDvdDrive -VMName $vm | Select-Object Path, ControllerType, ControllerNumber, ControllerLocation | Format-Table -AutoSize
Write-Host ("Boot order: " + ((Get-VMFirmware -VMName $vm).BootOrder | ForEach-Object { $_.Description }) -join ' -> ')

Write-Host '=== Starting VM ==='
Start-VM -Name $vm
Start-Sleep -Seconds 45
Get-VM -Name $vm | Select-Object Name, State, Status, Uptime | Format-List
Write-Host ("OS disk size: " + [math]::Round((Get-Item 'C:\Hyper-V\AD\BWANA-MAIL-01\BWANA-MAIL-01.vhdx').Length/1MB,1) + " MB")
