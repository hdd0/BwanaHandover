$ErrorActionPreference = 'Continue'
$names = 'BWANA-DC01','BWANA-DC02','BWANA-NAS-01','BWANA-OKD-01','BWANA-OKD-02','BWANA-OKD-03','BWANA-OKD-BOOTSTRAP'

foreach ($n in $names) {
    $v = Get-VM $n -ErrorAction SilentlyContinue
    if (-not $v) { Write-Host "=== $n : NOT FOUND ==="; continue }
    Write-Host "=== $($v.Name) ==="
    Write-Host ("  State       : " + $v.State)
    Write-Host ("  Gen/Firmware: Gen=" + $v.Generation + " Firmware=" + $v.Firmware)
    Write-Host ("  SecureBoot  : Enabled=" + $v.'Secure Boot'.Enabled + " Template=" + $v.'Secure Boot'.Template)
    Write-Host ("  Chipset     : " + $v.ChipsetType)
    Write-Host ("  OS reported : " + $v.OperatingSystem)
    Write-Host ("  Checkpoints : " + $v.CheckpointType)
    Write-Host "  -- Disks --"
    $v | Get-VMHardDiskDrive | ForEach-Object {
        Write-Host ("    Ctrl=" + $_.ControllerType + " Path=" + $_.Path)
    }
    Write-Host "  -- DVD --"
    $v | Get-VMDvdDrive | ForEach-Object {
        $p = if ($_.Path) { $_.Path } else { '(none)' }
        Write-Host ("    Ctrl=" + $_.ControllerType + " Path=" + $p + " ISO=" + $_.ISOPath)
    }
    $bo = (Get-VMFirmware $n).BootOrder
    Write-Host ("  -- BootOrder -- " + (($bo | ForEach-Object { $_.DevicePath }) -join ' | '))
    Write-Host ""
}
