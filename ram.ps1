. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
$os=Get-CimInstance Win32_OperatingSystem
SayOk '16-ram' ("host RAM free: " + [math]::Round($os.FreePhysicalMemory/1MB,1) + " GB / " + [math]::Round($os.TotalVisibleMemorySize/1MB,1) + " GB  (was 11.6 GB free at start)")
SayStart '17-audit' 'Auditing existing containers for CPU/MEM caps'
$rows = docker ps --format '{{.Names}}|{{.Image}}' 2>&1 | ForEach-Object {
  $p = $_ -split '\|'
  $s = docker inspect --format '{{.HostConfig.NanoCpus}}|{{.HostConfig.Memory}}|{{.HostConfig.RestartPolicy.Name}}' $p[0] 2>$null
  $v = $s -split '\|'
  $mem = if([int64]$v[1] -gt 0){ [math]::Round(([int64]$v[1])/1GB,2).ToString()+'G' } else { 'UNCAPPED' }
  $cpu = if([int64]$v[0] -gt 0){ ([int64]$v[0]/1e9).ToString()+' cpu' } else { 'UNCAPPED' }
  [PSCustomObject]@{ Name=$p[0]; CPU=$cpu; MEM=$mem; Restart=$v[2] }
}
$rows | Format-Table -AutoSize | Out-String -Width 120 | ForEach-Object { $_.TrimEnd() -split "`r?`n" | Where-Object {$_.Trim()} | ForEach-Object { Say '17-cap' ($(if($_ -match 'UNCAPPED'){'warn'}else{'info'})) $_.Trim() } }
SayOk '17-summary' ("containers: " + $rows.Count + "  uncapped: " + @($rows | Where-Object {$_.CPU -eq 'UNCAPPED'}).Count)
