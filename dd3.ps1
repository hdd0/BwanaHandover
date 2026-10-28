. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
SayStart '07-diagnose' 'Engine still down after 4min - collecting evidence'
Say '07-pipes' 'info' ('dockerDesktopLinuxEngine pipe exists: ' + (Test-Path '\\.\pipe\dockerDesktopLinuxEngine'))
Say '07-pipes' 'info' ('docker_engine pipe exists: ' + (Test-Path '\\.\pipe\docker_engine'))
Say '07-procs' 'info' ('backend procs: ' + ((Get-Process -Name 'com.docker.backend' -EA SilentlyContinue | Measure-Object).Count))
Say '07-vm' 'info' ('vmmem procs: ' + ((Get-Process -Name 'vmmem*' -EA SilentlyContinue | Measure-Object).Count))
$log = "$env:LOCALAPPDATA\Docker\log\host\com.docker.backend.exe.log"
if(Test-Path $log){
  SayStart '07-logs' 'Reading com.docker.backend.exe.log (last 30)'
  Get-Content $log -Tail 30 -EA SilentlyContinue | ForEach-Object { Say '07-backend-log' 'info' ($_ -replace '\s+',' ').Trim() }
} else { SayErr '07-logs' 'backend log missing' }
$elog = "$env:LOCALAPPDATA\Docker\log\vm\dockerd.log"
if(Test-Path $elog){ SayStart '07-dockerd' 'dockerd.log tail'; Get-Content $elog -Tail 20 | ForEach-Object { Say '07-dockerd-log' 'info' ($_ -replace '\s+',' ') } }
else { Say '07-dockerd' 'warn' 'no dockerd.log yet' }
