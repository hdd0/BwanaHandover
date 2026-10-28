# verify ISO boot files on host, then fix firmware on both DCs
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
Mount-DiskImage -ImagePath $iso | Out-Null
$drive = ((Get-DiskImage -ImagePath $iso | Get-Volume).DriveLetter + ':')
Write-Output ("ISO drive=" + $drive)
Write-Output ("bootx64.efi present=" + (Test-Path (Join-Path $drive 'efi\boot\bootx64.efi')) + " bootmgr.efi present=" + (Test-Path (Join-Path $drive 'efi\microsoft\boot\cdboot.efi')))
Dismount-DiskImage -ImagePath $iso | Out-Null
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Stop-VM -Name $vm -TurnOff -Force -ErrorAction SilentlyContinue
  $dvd = Get-VMDvdDrive -VMName $vm
  Set-VMFirmware -VMName $vm -EnableSecureBoot On -SecureBootTemplate 'MicrosoftUEFICertificateAuthority' -FirstBootDevice $dvd
  Write-Output ("FIXED " + $vm + " template=UEFI-CA dvd-first")
}
Get-VMFirmware BWANA-DC01, BWANA-DC02 | Format-Table VMName,SecureBoot,SecureBootTemplate | Out-String | Write-Output
Start-VM BWANA-DC01, BWANA-DC02
Start-Sleep 30
Get-VM BWANA-DC01, BWANA-DC02 | Format-Table Name,State,Uptime | Out-String | Write-Output
Write-Output DONE-FIXBOOT
