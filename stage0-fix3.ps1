$ErrorActionPreference = 'Continue'
$vmName = 'BWANA-GOLDEN-SRC'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'

Write-Output "=== ISO present on host? ==="
if (Test-Path $iso) { Write-Output ("YES - {0} GB" -f [math]::Round((Get-Item $iso).Length/1GB,2)) } else { Write-Output "NO - ISO missing"; exit 1 }

Write-Output ""
Write-Output "=== RE-CREATE DVD DRIVE to force a firmware boot entry ==="
try {
    $existing = (Get-VM -Name $vmName).DvdDrives
    if ($existing) {
        foreach ($d in $existing) { Remove-VMDvdDrive -VMDvdDrive $d -ErrorAction Stop; Write-Output "Removed existing DVD drive." }
    }
    Add-VMDvdDrive -VMName $vmName -Path $iso -Passthru -ErrorAction Stop | ForEach-Object { Write-Output ("Re-added DVD: {0}" -f $_.Path) }
} catch { Write-Output "DVD re-attach failed: $($_.Exception.Message)" }

Start-Sleep -Seconds 3
Write-Output ""
Write-Output "=== FIRMWARE BOOT ENTRIES AFTER RE-ATTACH ==="
$fw = Get-VMFirmware -VMName $vmName
$i = 0
foreach ($b in $fw.BootOrder) { $i++; Write-Output ("  [{0}] '{1}' path='{2}'" -f $i, $b.Description, $b.Path) }

Write-Output ""
Write-Output "=== SET BOOT ORDER: DVD first ==="
$entries = @($fw.BootOrder)
$dvd  = $entries | Where-Object { $_.Path -like '*.iso' -or $_.Description -match 'DVD' } | Select-Object -First 1
$hdd  = $entries | Where-Object { $_.Description -match 'SCSI|Disk' -and $_ -ne $dvd } | Select-Object -First 1
$net  = $entries | Where-Object { $_.Description -match 'Network|PXE' } | Select-Object -First 1
Write-Output ("dvd={0} hdd={1} net={2}" -f ($dvd -ne $null), ($hdd -ne $null), ($net -ne $null))
$new = @(); if ($dvd) { $new += $dvd }; if ($hdd) { $new += $hdd }; if ($net) { $new += $net }
if ($new.Count -ge 2 -and $dvd) {
    try { Set-VMFirmware -VMName $vmName -BootOrder $new -ErrorAction Stop; Write-Output "Boot order set with DVD first." }
    catch { Write-Output "Set-VMFirmware failed: $($_.Exception.Message)" }
} elseif (-not $dvd) {
    Write-Output "DVD still has no firmware boot entry; boot order unchanged."
}

Write-Output ""
Write-Output "=== FINAL STATE ==="
$vm = Get-VM -Name $vmName
$fw2 = Get-VMFirmware -VMName $vmName
$j = 0
foreach ($b in $fw2.BootOrder) { $j++; Write-Output ("  [{0}] {1} | {2}" -f $j, $b.Description, $b.Path) }
Write-Output ("State: {0} | MemoryStartup: {1} GB | Dynamic: {2}" -f $vm.State, [math]::Round([int64]$vm.MemoryStartup/1GB,1), $vm.DynamicMemoryEnabled)
Write-Output ""
Write-Output "=== INTEGRATION SERVICES ==="
try {
    $keys = $vm.IntegrationServicesState.Keys
    foreach ($k in $keys) {
        $val = $vm.IntegrationServicesState[$k].PrimaryStatusDescription
        Write-Output ("  {0} = {1}" -f $k, $val)
    }
} catch { Write-Output ("IS read failed: {0}" -f $_.Exception.Message) }