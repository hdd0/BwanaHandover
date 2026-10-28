$ErrorActionPreference = 'Stop'
$log = 'C:\STEP\BwanaAD\logs\phase1-watch-20260929.log'
"=== WATCH START $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Tee-Object $log -Append | Write-Output
for ($i = 1; $i -le 10; $i++) {
  foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
    $v = Get-VM -Name $vm -ErrorAction SilentlyContinue
    $hd = Get-VMHardDiskDrive -VMName $vm -ErrorAction SilentlyContinue | Where-Object { $_.Path -notlike '*answer-*.vhdx' } | Select-Object -First 1
    $sz = if ($hd) { (Get-Item $hd.Path -ErrorAction SilentlyContinue).Length } else { -1 }
    $hb = (Get-VMIntegrationService -VMName $vm -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*Heartbeat*' }).PrimaryStatusDescription
    ("[{0}] t+{1}m {2} state={3} uptime={4} heartbeat={5} osdisk_bytes={6}" -f (Get-Date -Format 'HH:mm:ss'), $i, $vm, $v.State, $v.Uptime, $hb, $sz) | Tee-Object $log -Append | Write-Output
  }
  if ($i -lt 10) { Start-Sleep -Seconds 60 }
}
"=== WATCH END $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Tee-Object $log -Append | Write-Output
