$ErrorActionPreference = 'Stop'
$n = 'BWANA-DC02'
$v = Get-VM -Name $n
Write-Output ("BEFORE " + $n + " state=" + $v.State + " assigned=" + [math]::Round((Get-VMMemory -VMName $n).AssignedSize / 1GB, 2) + "GB")

Write-Output 'Graceful ACPI shutdown (Stop-VM, not -TurnOff)...'
Stop-VM -Name $n
$deadline = (Get-Date).AddMinutes(5)
while ((Get-VM -Name $n).State -ne 'Off') {
    if ((Get-Date) -gt $deadline) { throw 'Graceful shutdown timed out after 5 minutes.' }
    Start-Sleep -Seconds 5
}
Write-Output ("STOPPED cleanly, state=" + (Get-VM -Name $n).State)

Set-VMMemory -VMName $n -StartupBytes (2GB) -DynamicMemoryEnabled $false
$s = Get-VMMemory -VMName $n
Write-Output ("SET memory startup=" + [math]::Round($s.StartupMemory / 1GB, 2) + "GB dynamic=" + $s.DynamicMemoryEnabled)

Start-VM -Name $n
Write-Output 'START issued; waiting for boot + autologon...'
$deadline = (Get-Date).AddMinutes(12)
$ready = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 15
    $state = (Get-VM -Name $n).State
    $assigned = [math]::Round((Get-VM -Name $n).MemoryAssigned / 1GB, 2)
    Write-Output ("  state=" + $state + " assigned=" + $assigned + "GB uptime=" + [math]::Round((Get-VM -Name $n).Uptime.TotalMinutes, 1) + "min")
    if ($state -eq 'Running' -and (Get-VM -Name $n).Uptime.TotalMinutes -gt 3) { $ready = $true; break }
}
if (-not $ready) { throw "$n did not come up within 12 minutes." }
Write-Output ("VERIFY " + $n + " is back up with " + [math]::Round((Get-VM -Name $n).MemoryAssigned / 1GB, 2) + "GB assigned")