. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
SayStart '13-backend-id' 'Identifying which VM now backs Docker'
Get-VM | Select-Object Name,State,@{n='RAM_GB';e={[math]::Round($_.MemoryAssigned/1GB,2)}},@{n='vCPU';e={$_.ProcessorCount}},Version | Format-Table -AutoSize | Out-String -Width 200 | ForEach-Object { $_.TrimEnd() -split "`r?`n" | Where-Object {$_.Trim()} | ForEach-Object { Say '13-vm' 'info' $_.Trim() } }
$j=[System.IO.File]::ReadAllText("$env:APPDATA\Docker\settings-store.json")|ConvertFrom-Json
Say '13-settings' 'info' ("memoryMiB=" + $j.memoryMiB + "  cpus=" + $j.cpus + "  wslEngineEnabled=" + $j.wslEngineEnabled)
