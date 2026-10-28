$os = Get-CimInstance Win32_OperatingSystem
"=== HOST MEM ==="
"Total GB : {0}" -f [math]::Round($os.TotalVisibleMemorySize/1MB,1)
"Free  GB : {0}" -f [math]::Round($os.FreePhysicalMemory/1MB,1)
"Used  %  : {0}" -f [math]::Round((1-($os.FreePhysicalMemory/$os.TotalVisibleMemorySize))*100,1)
"CommitLimit GB : {0}" -f [math]::Round((Get-Counter '\Memory\Commit Limit').CounterSamples.CookedValue/1GB,1)
"Committed    GB : {0}" -f [math]::Round((Get-Counter '\Memory\Committed Bytes').CounterSamples.CookedValue/1GB,1)
"Pages/sec        : {0}" -f [math]::Round((Get-Counter '\Memory\Pages/sec').CounterSamples.CookedValue,0)
"=== HOST CPU ==="
"CPU load %  : {0}" -f (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
"=== TOP MEM PROCESSES ==="
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name,Id,@{n="RAM_MB";e={[math]::Round($_.WorkingSet64/1MB)}},@{n="CPU_s";e={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize
"=== HYPERVISOR / VM WORKERS ==="
Get-Process | Where-Object { $_.Name -match 'vmwp|vmms|vmcompute' } | Select-Object Name,Id,@{n="RAM_MB";e={[math]::Round($_.WorkingSet64/1MB)}},@{n="CPU_s";e={[math]::Round($_.CPU,1)}} | Format-Table -AutoSize
"=== VM ASSIGNED MEM (from Hyper-V) ==="
Get-VM | Where-Object {$_.State -eq 'Running'} | Select-Object Name,@{n="AssignedGB";e={[math]::Round($_.MemoryAssigned/1GB,2)}},@{n="StartupGB";e={[math]::Round($_.MemoryStartup/1GB,2)}},@{n="CPU_Limit_pct";e={$_.ProcessorCount}} | Format-Table -AutoSize
