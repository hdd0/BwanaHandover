$ErrorActionPreference = "Continue"
Write-Host "=== Re-attach TrueNAS ISO to BWANA-NAS-01 ==="
$iso = "E:\BWANA\OKD\ISO\TrueNAS-SCALE-25.10.7.iso"
Write-Host ("ISO exists: " + (Test-Path $iso))
$vm = Get-VM -Name "BWANA-NAS-01" -ErrorAction SilentlyContinue
if (-not $vm) { Write-Host "VM MISSING"; exit 1 }
$dvd = Get-VMDvdDrive -VMName "BWANA-NAS-01" -ErrorAction SilentlyContinue
Write-Host ("DVD drive present: " + ($dvd -ne $null) + " current path: '" + $dvd.Path + "'")
if ($dvd.Path -ne $iso) {
    if ($dvd) { Set-VMDvdDrive -VMName "BWANA-NAS-01" -Path $iso }
    else { Add-VMDvdDrive -VMName "BWANA-NAS-01" -Path $iso }
    Write-Host "ISO (re)attached"
}
$after = (Get-VMDvdDrive -VMName "BWANA-NAS-01").Path
Write-Host ("DVD path now: " + $after)
if ($after -ne $iso) { Write-Host "ATTACH_FAILED"; exit 1 }
# restore DVD-first boot order
$hdd = @(Get-VMHardDiskDrive -VMName "BWANA-NAS-01" -ErrorAction SilentlyContinue)
$d = Get-VMDvdDrive -VMName "BWANA-NAS-01"
if ($hdd.Count -gt 0) { Set-VMFirmware -VMName "BWANA-NAS-01" -BootOrder (@($d) + $hdd); Write-Host "Boot order DVD-first restored" }
Write-Host ("VM state: " + (Get-VM -Name "BWANA-NAS-01").State)
Write-Host "NAS_ISO_OK"
