$ErrorActionPreference = 'Continue'
$vmName = 'BWANA-GOLDEN-SRC'
$before = Get-VM -Name $vmName
Write-Output "=== BEFORE ==="
Write-Output "State {0} | Heartbeat {1} | MemStartup {2} GB | MemAssigned {3} GB | Uptime {4}" -f $before.State, $before.Heartbeat, [math]::Round($before.MemoryStartup/1GB,1), [math]::Round($before.MemoryAssigned/1GB,1), $before.Uptime
Write-Output ""
Write-Output "=== STOPPING VM (empty disk, PXE-spinning, nothing to lose) ==="
try { Stop-VM -Name $vmName -Force -ErrorAction Stop; Write-Output "Stop requested." } catch { Write-Output "Stop failed: $($_.Exception.Message)" }
$i = 0
while ((Get-VM -Name $vmName).State -ne 'Off' -and $i -lt 30) { Start-Sleep -Seconds 2; $i++ }
$vm = Get-VM -Name $vmName
Write-Output "State now: $($vm.State)"
if ($vm.State -ne 'Off') { Write-Output "ABORT: VM did not reach Off; not changing firmware."; exit 1 }
Write-Output ""
Write-Output "=== APPLY: memory 8 GB (dynamic, max 8) ==="
try {
    Set-VM -Name $vmName -MemoryStartupBytes 8GB -MemoryLow 4GB -MemoryHigh 8GB -DynamicMemory -ErrorAction Stop
    Write-Output "Memory set to 8 GB startup, low 4 GB, high 8 GB."
} catch { Write-Output "Memory set failed: $($_.Exception.Message)" }
Write-Output ""
Write-Output "=== APPLY: boot order DVD -> HDD -> Network ==="
try {
    $dvd  = Get-VMFirmware -VMName $vmName | Select-Object -ExpandProperty BootOrder | Where-Object { $_.Description -like '*DVD*' -or $_.Path -like '*.iso' }
    $hdd  = Get-VMFirmware -VMName $vmName | Select-Object -ExpandProperty BootOrder | Where-Object { $_.Description -like '*Hard Disk*' -or $_.Description -like '*SCSI*' }
    $net  = Get-VMFirmware -VMName $vmName | Select-Object -ExpandProperty BootOrder | Where-Object { $_.Description -like '*Network*' -or $_.Description -like '*PXE*' }
    Write-Output "Detected DVD entries : $($dvd.Count)"
    Write-Output "Detected HDD entries : $($hdd.Count)"
    Write-Output "Detected NET entries : $($net.Count)"
    $new = @()
    if ($dvd) { $new += $dvd[0] }
    if ($hdd) { $new += $hdd[0] }
    if ($net) { $new += $net[0] }
    if ($new.Count -ge 1) {
        Set-VMFirmware -VMName $vmName -BootOrder $new -ErrorAction Stop
        Write-Output "Boot order set."
    } else { Write-Output "No usable boot entries detected; boot order unchanged." }
} catch { Write-Output "Boot order failed: $($_.Exception.Message)" }
Write-Output ""
Write-Output "=== APPLY: enable Guest Service Interface (heartbeat/PowerShell Direct once OS installed) ==="
try {
    Enable-VMIntegrationService -Name 'Guest Service Interface' -VMName $vmName -ErrorAction Stop
    Write-Output "Guest Service Interface enabled."
} catch { Write-Output "GSI enable: $($_.Exception.Message)" }
Write-Output ""
Write-Output "=== AFTER ==="
$after = Get-VM -Name $vmName
$fw = Get-VMFirmware -VMName $vmName
Write-Output "State {0} | MemStartup {1} GB | MemAssigned {2} GB" -f $after.State, [math]::Round($after.MemoryStartup/1GB,1), [math]::Round($after.MemoryAssigned/1GB,1)
Write-Output "Boot order:"
$fw.BootOrder | ForEach-Object { Write-Output ("   - {0} | {1}" -f $_.Description, $_.Path) }
Write-Output "Integration services:"
$after.IntegrationServicesState.Keys | ForEach-Object { Write-Output ("   - {0}" -f $_) }