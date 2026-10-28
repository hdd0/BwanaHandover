. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
SayStart '06-docker-start' 'Starting Docker Desktop on Hyper-V backend'
$p = Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -PassThru
SayOk '06-launched' ("Docker Desktop PID " + $p.Id + " launched")
$deadline = (Get-Date).AddMinutes(4)
$ready = $false
while((Get-Date) -lt $deadline){
  Start-Sleep -Seconds 10
  $j = Start-Job { docker --context desktop-linux version --format '{{.Server.Version}}' 2>&1 }
  if(Wait-Job $j -Timeout 15){
    $v = (Receive-Job $j) -join ' '
    if($v -match '^\d+\.\d+'){ SayOk '06-engine' ("Docker engine " + $v.Trim() + " answering"); $ready=$true; break }
    else { Say '06-wait' 'info' ("engine not ready yet: " + $v.Trim().Substring(0,[Math]::Min(90,$v.Trim().Length))) }
  } else { Say '06-wait' 'info' 'engine probe timed out' }
  Stop-Job $j -EA SilentlyContinue; Remove-Job $j -Force -EA SilentlyContinue
}
if(-not $ready){ SayErr '06-engine' 'Docker engine did not come up within 4 minutes' }
