$ErrorActionPreference = 'Stop'
$vm = 'BWANA-DC02'

# 1. Current state
$fw = Get-VMFirmware -VMName $vm
Write-Host "BEFORE: EnableSecureBoot=$($fw.EnableSecureBoot) Template=$($fw.SecureBootTemplate) State=$((Get-VM $vm).State)"

# 2. Force-stop (no OS running, stuck at UEFI -> safe)
$cur = (Get-VM $vm).State
if ($cur -ne 'Off') {
    Stop-VM -Name $vm -Force -TurnOff
    Write-Host "Force-stopped $vm"
}

# 3. Disable Secure Boot so the installer ISO can boot
Set-VMFirmware -VMName $vm -EnableSecureBoot Off
$fw2 = Get-VMFirmware -VMName $vm
Write-Host "AFTER SET: EnableSecureBoot=$($fw2.EnableSecureBoot) Template=$($fw2.SecureBootTemplate)"

# 4. Start it again
Start-VM -Name $vm | Out-Null
Start-Sleep -Seconds 8
$st = (Get-VM $vm).State
Write-Host "Restarted $vm -> State=$st"
