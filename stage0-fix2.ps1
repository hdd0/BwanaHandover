$ErrorActionPreference = 'Continue'
$vmName = 'BWANA-GOLDEN-SRC'
Write-Output "=== RAW BOOT ENTRIES (Description + Path + DevicePath) ==="
$fw = Get-VMFirmware -VMName $vmName
$i = 0
foreach ($b in $fw.BootOrder) {
    $i++
    Write-Output ("[{0}] Desc='{1}'" -f $i, $b.Description)
    Write-Output ("     Path='{0}'" -f $b.Path)
    Write-Output ("     DevicePath='{0}'" -f ($b.DevicePath | Out-String).Trim())
}
Write-Output ""
Write-Output "=== DVD DRIVE ATTACHMENT ==="
$dvds = (Get-VM -Name $vmName).DvdDrives
foreach ($d in $dvds) { Write-Output ("DvdDrive Path='{0}'" -f $d.Path) }
Write-Output ""
Write-Output "=== FIX 1: MEMORY (VM is Off) ==="
try {
    Set-VM -Name $vmName -MemoryStartupBytes 8GB -DynamicMemory -ErrorAction Stop
    Write-Output "Set-VM: startup 8 GB, dynamic enabled."
} catch { Write-Output "Set-VM failed: $($_.Exception.Message)" }
try {
    Set-VMMemory -VMName $vmName -Low 4GB -High 8GB -ErrorAction Stop
    Write-Output "Set-VMMemory: low 4 GB, high 8 GB."
} catch { Write-Output "Set-VMMemory failed: $($_.Exception.Message)" }
$vm = Get-VM -Name $vmName
Write-Output ("Memory now: startup {0} GB, assigned {1} GB, dynamic {2}" -f [math]::Round([int64]$vm.MemoryStartup/1GB,1), [math]::Round([int64]$vm.MemoryAssigned/1GB,1), $vm.DynamicMemoryEnabled)
Write-Output ""
Write-Output "=== FIX 2: BOOT ORDER using Path-based DVD detection ==="
$entries = @($fw.BootOrder)
$dvdEntry = $entries | Where-Object { $_.Path -like '*.iso' } | Select-Object -First 1
if (-not $dvdEntry) { $dvdEntry = $entries | Where-Object { $_.Description -match 'DVD' } | Select-Object -First 1 }
$hddEntry = $entries | Where-Object { $_ -ne $dvdEntry -and $_.Description -match 'SCSI|Disk|HDD' } | Select-Object -First 1
$netEntry = $entries | Where-Object { $_.Description -match 'Network|PXE' } | Select-Object -First 1
Write-Output ("DVD found : {0} ({1})" -f ($dvdEntry -ne $null), $(if($dvdEntry){$dvdEntry.Description}else{'none'}))
Write-Output ("HDD found : {0} ({1})" -f ($hddEntry -ne $null), $(if($hddEntry){$hddEntry.Description}else{'none'}))
Write-Output ("NET found : {0} ({1})" -f ($netEntry -ne $null), $(if($netEntry){$netEntry.Description}else{'none'}))
$new = @()
if ($dvdEntry) { $new += $dvdEntry }
if ($hddEntry) { $new += $hddEntry }
if ($netEntry) { $new += $netEntry }
if ($new.Count -gt 0) {
    try {
        Set-VMFirmware -VMName $vmName -BootOrder $new -ErrorAction Stop
        Write-Output "Boot order applied with $($new.Count) entries."
    } catch { Write-Output "Set-VMFirmware failed: $($_.Exception.Message)" }
}
Write-Output ""
Write-Output "=== VERIFY ==="
$fw2 = Get-VMFirmware -VMName $vmName
$j = 0
foreach ($b in $fw2.BootOrder) { $j++; Write-Output ("  [{0}] {1} | {2}" -f $j, $b.Description, $b.Path) }
$vm2 = Get-VM -Name $vmName
Write-Output ("State: {0} | Memory startup {1} GB" -f $vm2.State, [math]::Round([int64]$vm2.MemoryStartup/1GB,1))
$gsi = $vm2.IntegrationServicesState
Write-Output ("GSI present: {0}" -f ($gsi -contains 'Guest Service Interface'))