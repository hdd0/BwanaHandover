$vmwp = Get-Process -Name 'vmwp' -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq 379312 }
if ($vmwp) {
    "Killing vmwp PID $($vmwp.Id)"
    Stop-Process -Id $vmwp.Id -Force
    Start-Sleep -Seconds 3
}
$remaining = Get-Process -Name 'vmwp' -ErrorAction SilentlyContinue | Select-Object Id
"Remaining vmwp processes: $($remaining | ForEach-Object { $_.Id })"
