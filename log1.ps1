. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID = 'MIGRATE-DOCKER-20261010'
SayStart 'Docker migration started. WSL service was wedged (0x8007274c); docker engine returned 500.'
SayOk '00-discovery' 'Host NDIRANDEONE / 64GB / 12 vCPU / 8 Hyper-V VMs running'
SayOk '01-kill' 'Killed 14 hung docker CLI procs + com.docker.backend'
SayOk '02-wsl' 'wsl --shutdown OK - vmmemWSL released (3442MB -> 0)'
"DEPLOYID=" + (Get-DeployId)
