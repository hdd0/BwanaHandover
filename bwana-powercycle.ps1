$ErrorActionPreference = 'Stop'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    Stop-VM -Name $vm -TurnOff -Force -ErrorAction Stop
    Write-Output ("{0}: powered off" -f $vm)
  } catch { Write-Output ("{0}: poweroff FAILED: {1}" -f $vm, $_.Exception.Message) }
}
Start-Sleep -Seconds 5
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    Set-VMFirmware -VMName $vm -SecureBootTemplate MicrosoftWindows -ErrorAction Stop
    Write-Output ("{0}: template now={(Get-VMFirmware -VMName $vm).SecureBootTemplate}" -f $vm)
  } catch { Write-Output ("{0}: template FAILED: {1}" -f $vm, $_.Exception.Message) }
}
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try { Start-VM -Name $vm -ErrorAction Stop; Write-Output ("{0}: started" -f $vm) }
  catch { Write-Output ("{0}: start FAILED: {1}" -f $vm, $_.Exception.Message) }
}
Write-Output 'waiting 110s for boot attempt...'
Start-Sleep -Seconds 110
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $v = Get-VM -Name $vm
  $hd = Get-VMHardDiskDrive -VMName $vm | Where-Object { $_.Path -notlike '*answer-*.vhdx' } | Select-Object -First 1
  $sz = (Get-Item $hd.Path).Length
  Write-Output ("{0}: state={1} uptime={2} osdisk_bytes={3}" -f $vm, $v.State, $v.Uptime, $sz)
}
Write-Output '--- fresh 18604 events (last 5 min) ---'
$cutoff = (Get-Date).AddMinutes(-5)
$ev = Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-Worker-Admin' -MaxEvents 40 -ErrorAction SilentlyContinue |
  Where-Object { $_.Id -eq 18604 -and $_.TimeCreated -ge $cutoff } |
  Select-Object TimeCreated, Message | Format-List | Out-String
if ([string]::IsNullOrWhiteSpace($ev)) { Write-Output '(none - boot validation passed)' } else { $ev | Write-Output }
