. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'

SayStart '03-wsl-restart' 'Restarting WslService to clear the 0x8007274c wedge'
Restart-Service WslService -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5
$svc = Get-Service WslService
SayOk '03-wsl-service' ("WslService = " + $svc.Status)

SayStart '04-wsl-verify' 'Probing wsl for health'
$job = Start-Job { & wsl.exe -l -v 2>&1 | Out-String }
$ok = Wait-Job $job -Timeout 45
if($ok){
  $out = (Receive-Job $job) -replace "`0",''
  SayOk '04-wsl-healthy' 'wsl -l -v responded'
  $out -split "`r?`n" | Where-Object {$_.Trim()} | ForEach-Object { Say '04-wsl-list' 'info' $_.Trim() }
} else { SayErr '04-wsl-healthy' 'wsl still not responding after service restart' }
Stop-Job $job -EA SilentlyContinue; Remove-Job $job -Force -EA SilentlyContinue
