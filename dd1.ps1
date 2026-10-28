. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
$store = "$env:APPDATA\Docker\settings-store.json"
$bk = "$env:APPDATA\Docker\settings-store.json.bak-migrate"
SayStart '05-backend-switch' 'Switching Docker Desktop WSL2 -> Hyper-V backend'
if(-not (Test-Path $bk)){ Copy-Item $store $bk -Force; SayOk '05-backup' ("Backed up settings-store.json -> " + $bk) }
$j = Get-Content $store -Raw | ConvertFrom-Json
Say '05-current' 'info' ("wslEngineEnabled(before)=" + $j.wslEngineEnabled + "  memoryMiB=" + $j.memoryMiB + "  cpus=" + $j.cpus)
$j.wslEngineEnabled = $false
$j | ConvertTo-Json -Depth 20 | Set-Content $store -Encoding UTF8
$j2 = Get-Content $store -Raw | ConvertFrom-Json
SayOk '05-written' ("wslEngineEnabled(after)=" + $j2.wslEngineEnabled)
