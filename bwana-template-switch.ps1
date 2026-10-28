$ErrorActionPreference = 'Stop'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    Set-VMFirmware -VMName $vm -SecureBootTemplate MicrosoftWindows -ErrorAction Stop
    $fw = Get-VMFirmware -VMName $vm
    Write-Output ("{0}: template now={1}" -f $vm, $fw.SecureBootTemplate)
    Restart-VM -Name $vm -Force -ErrorAction Stop
    Write-Output ("{0}: restarted" -f $vm)
  } catch { Write-Output ("{0}: FAILED: {1}" -f $vm, $_.Exception.Message) }
}
Write-Output 'waiting 100s for boot attempt...'
Start-Sleep -Seconds 100
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $v = Get-VM -Name $vm
  $hd = Get-VMHardDiskDrive -VMName $vm | Where-Object { $_.Path -notlike '*answer-*.vhdx' } | Select-Object -First 1
  $sz = (Get-Item $hd.Path).Length
  Write-Output ("{0}: state={1} uptime={2} osdisk_bytes={3}" -f $vm, $v.State, $v.Uptime, $sz)
}
Write-Output '--- fresh 18604 events ---'
$cutoff = (Get-Date).AddMinutes(-5)
Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-Worker-Admin' -MaxEvents 40 -ErrorAction SilentlyContinue |
  Where-Object { $_.Id -eq 18604 -and $_.TimeCreated -ge $cutoff } |
  Select-Object TimeCreated, Message | Format-List | Out-String | Write-Output
Write-Output '(no fresh 18604 = boot validation passed)'
