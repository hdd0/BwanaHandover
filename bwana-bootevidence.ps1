$ErrorActionPreference = 'Stop'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $fw = Get-VMFirmware -VMName $vm
  $b0 = ($fw.BootOrder | Select-Object -First 1).Device
  Write-Output ("{0}: boot0={1} secureboot={2} template={3}" -f $vm, $b0, $fw.SecureBoot, $fw.SecureBootTemplate)
  $dvd = Get-VMDvdDrive -VMName $vm | Select-Object -First 1
  Write-Output ("{0}: dvdpath={1} readable={2}" -f $vm, $dvd.Path, (Test-Path $dvd.Path))
}
Write-Output '--- Hyper-V-Worker-Admin (last 20, filtered) ---'
Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-Worker-Admin' -MaxEvents 60 -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -match 'BWANA-DC0' } |
  Select-Object TimeCreated, Id, Message | Format-List | Out-String | Write-Output
Write-Output '--- Hyper-V-VMMS-Admin boot events (last 20, filtered) ---'
Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-VMMS-Admin' -MaxEvents 60 -ErrorAction SilentlyContinue |
  Where-Object { $_.Message -match 'BWANA-DC0' } |
  Select-Object TimeCreated, Id, Message | Format-List | Out-String | Write-Output
