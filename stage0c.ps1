$ErrorActionPreference = 'Continue'
$gs = Get-VM -Name 'BWANA-GOLDEN-SRC'
Write-Output "=== HARD DRIVES (object model) ==="
$gs.HardDrives | ForEach-Object {
    Write-Output ("Controller {0} | ControllerType {1} | Path {2}" -f $_.ControllerNumber, $_.ControllerType, $_.Path)
    try {
        $vhd = Get-VHD -Path $_.Path -ErrorAction Stop
        Write-Output ("   Size {0} GB | FileSize {1} GB | Type {2} | VHDType {3}" -f [math]::Round($vhd.Size/1GB,1), [math]::Round($vhd.FileSize/1GB,1), $vhd.VhdType, $vhd.FileType)
        Write-Output ("   LastWrite {0}" -f (Get-Item $_.Path).LastWriteTime)
        Get-VHD -Path $_.Path | Get-VHDPartition | ForEach-Object { Write-Output ("   Partition {0}: type {1} size {2} GB drive '{3}'" -f $_.PartitionNumber, $_.Type, [math]::Round($_.Size/1GB,1), $_.DriveLetter) }
    } catch { Write-Output "   VHD inspect failed: $($_.Exception.Message)" }
}
Write-Output ""
Write-Output "=== NETWORK ADAPTERS ==="
$gs.NetworkAdapters | ForEach-Object {
    Write-Output ("Name {0} | Switch {1} | Status {2} | Mac {3} | IPs [{4}]" -f $_.Name, $_.SwitchName, ($_.Status -join ','), $_.MacAddress, ($_.IPAddresses -join ','))
}
Write-Output ""
Write-Output "=== DVD / ISO ATTACHED? ==="
Write-Output ("DvdDrives count: {0}" -f $gs.DvdDrives.Count)
$gs.DvdDrives | ForEach-Object { Write-Output ("  Path: {0} | Host: {1}" -f $_.Path, $_.HostPath) }
Write-Output ""
Write-Output "=== CHECKPOINT / STATE ==="
Write-Output ("Checkpoints: {0}" -f $gs.Checkpoints.Count)
Write-Output ("AutomaticStartAction {0} | AutomaticStopAction {1}" -f $gs.AutomaticStartAction, $gs.AutomaticStopAction)
Write-Output ("CheckpointType: {0}" -f $gs.CheckpointType)
Write-Output ""
Write-Output "=== HOST VM SETTINGS ==="
Write-Output ("LowMemoryMonitorAndStartDomain {0} | AutoStart {1}" -f (Get-VMHost).LowMemoryMonitorAndStartDomain, (Get-VMHost).EnableAutomaticStartAction)