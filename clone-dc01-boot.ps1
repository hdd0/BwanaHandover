Write-Output '=== BEFORE ==='
Get-VMFirmware -VMName 'BWANA-GOLDEN-SRC' | Select-Object SecureBoot,SecureBootTemplate,BootOrder | Format-List | Out-String | Write-Output
Write-Output '=== DC01 reference ==='
Get-VMFirmware -VMName 'BWANA-DC01' | Select-Object BootOrder | Format-List | Out-String | Write-Output
Write-Output '=== Stopping GOLDEN-SRC ==='
Stop-VM -Name 'BWANA-GOLDEN-SRC' -Force -ErrorAction Stop
$deadline = (Get-Date).AddMinutes(2)
while ((Get-VM -Name 'BWANA-GOLDEN-SRC').State -ne 'Off') {
  if ((Get-Date) -gt $deadline) { throw 'GOLDEN-SRC did not reach Off in 2min' }
  Start-Sleep 3
}
Write-Output 'STATE=Off confirmed'
$dvd = Get-VMDvdDrive -VMName 'BWANA-GOLDEN-SRC'
$hdd = Get-VMHardDiskDrive -VMName 'BWANA-GOLDEN-SRC' | Select-Object -First 1
$net = Get-VMNetworkAdapter -VMName 'BWANA-GOLDEN-SRC' | Select-Object -First 1
Write-Output ("DVD=" + $dvd.Path)
Write-Output ("HDD=" + $hdd.Path)
Set-VMFirmware -VMName 'BWANA-GOLDEN-SRC' -BootOrder $dvd,$hdd,$net -ErrorAction Stop
Enable-VMIntegrationService -VMName 'BWANA-GOLDEN-SRC' -Name 'Guest Service Interface' -ErrorAction SilentlyContinue
Set-VM -Name 'BWANA-GOLDEN-SRC' -AutomaticStartAction Start -AutomaticStopAction Save -ErrorAction SilentlyContinue
Write-Output '=== AFTER ==='
Get-VMFirmware -VMName 'BWANA-GOLDEN-SRC' | Select-Object SecureBoot,SecureBootTemplate,BootOrder | Format-List | Out-String | Write-Output
Write-Output '=== Starting GOLDEN-SRC ==='
Start-VM -Name 'BWANA-GOLDEN-SRC' -ErrorAction Stop
Start-Sleep 5
Get-VM -Name 'BWANA-GOLDEN-SRC' | Select-Object Name,State | Format-Table -AutoSize | Out-String | Write-Output
Write-Output 'CLONE-BOOT-OK'
