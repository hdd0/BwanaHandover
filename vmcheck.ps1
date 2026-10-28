Get-VM | Select-Object Name,State,Status,Generation,Version,CPUUsage,MemoryAssigned,Uptime,AutomaticStartAction,AutomaticStopAction,@{n="Host";e={$_.ComputerName}} | Sort-Object Name | Format-Table -AutoSize
"=== CONFIG LOCATION ==="
Get-VM | ForEach-Object {
  $c = Get-VMHardDiskDrive -VM $_ -ErrorAction SilentlyContinue
  [PSCustomObject]@{ Name=$_.Name; State=$_.State; VhdX=(($c | ForEach-Object { $_.Path }) -join "; "); Config=((Get-VM -Name $_.Name).ConfigurationLocation) }
} | Format-List
