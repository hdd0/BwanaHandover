$ErrorActionPreference = 'Continue'

Write-Host "=== VM LIST ===" -ForegroundColor Cyan
Get-VM | Select-Object Name, State, Generation,
    @{n='CPU';e={$_.ProcessorCount}},
    @{n='RAMGB';e={[math]::Round($_.MemoryAssigned/1GB,1)}},
    @{n='Switch';e={($_.NetworkAdapters | Select-Object -First 1).SwitchName}} |
    Format-Table -AutoSize | Out-String -Width 250 | Write-Host

Write-Host "=== HOST MEMORY ===" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
Write-Host ("TotalGB: {0}  FreeGB: {1}" -f [math]::Round($os.TotalVisibleMemorySize/1MB,1), [math]::Round($os.FreePhysicalMemory/1MB,1))

Write-Host "=== GOLDEN-SRC DETAIL ===" -ForegroundColor Cyan
Get-VM -Name 'BWANA-GOLDEN-SRC' -ErrorAction SilentlyContinue | Format-List Name, State, Generation, Status, Heartbeat, ProcessorCount, MemoryAssigned, Path | Out-String -Width 200 | Write-Host

Write-Host "=== GOLDEN-SRC NETWORK ===" -ForegroundColor Cyan
Get-VMNetworkAdapter -VMName 'BWANA-GOLDEN-SRC' -ErrorAction SilentlyContinue | Format-List Name, SwitchName, IPAddresses, MacAddress, Status | Out-String -Width 200 | Write-Host

Write-Host "=== GOLDEN-SRC FIRMWARE ===" -ForegroundColor Cyan
Get-VMFirmware -VMName 'BWANA-GOLDEN-SRC' -ErrorAction SilentlyContinue | Select-Object BootOrder, SecureBootEnabled, SecureBootTemplate | Format-List | Out-String -Width 200 | Write-Host

Write-Host "=== GOLDEN-SRC DISKS / DVD ===" -ForegroundColor Cyan
Get-VMHardDiskDrive -VMName 'BWANA-GOLDEN-SRC' -ErrorAction SilentlyContinue | Format-List Path, Size | Out-String -Width 200 | Write-Host
Get-VMDvdDrive -VMName 'BWANA-GOLDEN-SRC' -ErrorAction SilentlyContinue | Format-List Path, ControllerNumber, ControllerLocation | Out-String -Width 200 | Write-Host

Write-Host "=== EXCH / MAIL VMs ===" -ForegroundColor Cyan
foreach ($n in 'BWANA-EXCH-01','BWANA-MAIL-01') {
  $v = Get-VM -Name $n -ErrorAction SilentlyContinue
  if ($v) { Write-Host "$n : $($v.State)" -ForegroundColor Yellow } else { Write-Host "$n : DOES NOT EXIST" -ForegroundColor Red }
}

Write-Host "=== VHDX FILES ===" -ForegroundColor Cyan
Get-ChildItem -Path 'C:\Hyper-V' -Recurse -Filter '*.vhdx' -ErrorAction SilentlyContinue |
  Select-Object FullName, @{n='GB';e={[math]::Round($_.Length/1GB,2)}}, LastWriteTime |
  Format-Table -AutoSize | Out-String -Width 250 | Write-Host
