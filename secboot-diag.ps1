$ErrorActionPreference = 'Continue'
foreach ($n in 'BWANA-DC01','BWANA-DC02') {
    Write-Host "=== $n ==="
    $fw = Get-VMFirmware -VMName $n
    Write-Host ("  Firmware          : " + $fw.Firmware)
    Write-Host ("  SecureBootEnabled : " + $fw.EnableSecureBoot)
    Write-Host ("  SecureBootTemplate: " + $fw.SecureBootTemplate)
    Write-Host ("  BootOrder:")
    $i = 0
    foreach ($b in $fw.BootOrder) {
        $i++
        $desc = switch -Regex ($b.DevicePath) {
            'PciRoot\(0x0\)'                  { 'HARDDISK (disk 0x0)' }
            'PciRoot\(0x1\)'                  { 'DVD' }
            'PciRoot\(0x2\)'                  { 'DISK 0x2 (unattend answer file)' }
            'IPv4'                            { 'NETWORK (PXE)' }
            default                           { 'other' }
        }
        Write-Host ("    [$i] $desc")
    }
    Write-Host ""
}
Write-Host "=== DVD ISO present? ==="
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
if (Test-Path $iso) {
    $f = Get-Item $iso
    Write-Host ("  EXISTS: {0}  {1:N2} GB" -f $f.Name, ($f.Length/1GB))
} else { Write-Host "  MISSING: $iso" }

Write-Host ""
Write-Host "=== DC OS disk size (is it installed?) ==="
foreach ($d in 'C:\Hyper-V\AD\BWANA-DC01\BWANA-DC01.vhdx','C:\Hyper-V\AD\BWANA-DC02\BWANA-DC02.vhdx','C:\STEP\unattend\answer-DC02.vhdx') {
    if (Test-Path $d) { $f = Get-Item $d; Write-Host ("  {0} = {1:N2} GB" -f $f.Name, ($f.Length/1GB)) }
    else { Write-Host "  $d MISSING" }
}
