. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
SayStart '10-restart' 'Restarting Docker Desktop with valid settings on Hyper-V backend'
Get-Process -Name 'Docker Desktop','com.docker.backend','com.docker.build' -EA SilentlyContinue | ForEach-Object { try{$_.Kill()}catch{} }
Start-Sleep 5
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe' | Out-Null
SayOk '10-launched' 'Docker Desktop relaunched'

$deadline=(Get-Date).AddMinutes(5); $ready=$false
while((Get-Date) -lt $deadline){
  Start-Sleep 12
  $j = Start-Job { docker --context desktop-linux version --format '{{.Server.Version}}' 2>&1 }
  if(Wait-Job $j -Timeout 15){
    $v = ((Receive-Job $j) -join ' ').Trim()
    if($v -match '^\d+\.\d+'){ SayOk '10-engine' ("Docker engine " + $v + " is UP"); $ready=$true; break }
    Say '10-wait' 'info' ($v.Substring(0,[Math]::Min(100,$v.Length)))
  } else { Say '10-wait' 'info' 'probe timed out' }
  Stop-Job $j -EA SilentlyContinue; Remove-Job $j -Force -EA SilentlyContinue
}
if(-not $ready){
  SayErr '10-engine' 'still down'
  SayStart '11-evidence' 'Reading backend crash reason'
  Get-Content "$env:LOCALAPPDATA\Docker\log\host\com.docker.backend.exe.log" -Tail 12 -EA SilentlyContinue |
    ForEach-Object { Say '11-log' 'info' ($_ -replace '\s+',' ').Trim().Substring(0,[Math]::Min(220,($_ -replace '\s+',' ').Trim().Length)) }
}
