. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
SayStart '12-verify' 'Confirming backend type, containers, resources'
$info = docker info --format '{{.NCPU}}|{{.MemTotal}}|{{.Driver}}|{{.OperatingSystem}}' 2>&1
SayOk '12-info' ("NCPU/Mem/Driver/OS = " + $info)
$cpu=[int]($info -split '\|')[0]; $memGB=[math]::Round(([int64](($info -split '\|')[1]))/1GB,2)
SayOk '12-ceiling' ("Docker gets " + $cpu + " vCPU and " + $memGB + " GB RAM")
$ps = docker ps -a --format '{{.Names}} :: {{.Status}}' 2>&1
if($ps){ $ps | ForEach-Object { Say '12-container' 'info' $_ } } else { Say '12-container' 'info' '(none)' }
SayOk '12-vmmem' ('vmmemWSL procs: ' + ((Get-Process vmmem* -EA SilentlyContinue|Measure-Object).Count) + '  vmmemWSL RAM_MB: ' + [math]::Round(((Get-Process vmmemWSL -EA SilentlyContinue|Measure-Object WorkingSet64 -Sum).Sum/1MB)))
$os=Get-CimInstance Win32_OperatingSystem
SayOk '12-host' ("host free RAM now: " + [math]::Round($os.FreePhysicalMemory/1MB,1) + " GB of " + [math]::Round($os.TotalVisibleMemorySize/1MB,1) + " GB")
