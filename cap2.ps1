. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
SayStart '15-restart' 'Restarting Docker Desktop to apply 12GB/6vCPU ceiling'
Get-Process -Name 'Docker Desktop','com.docker.backend' -EA SilentlyContinue | ForEach-Object { try{$_.Kill()}catch{} }
Start-Sleep 5
Start-Process -FilePath 'C:\Program Files\Docker\Docker\Docker Desktop.exe' | Out-Null
$deadline=(Get-Date).AddMinutes(5); $ready=$false
while((Get-Date) -lt $deadline){
  Start-Sleep 12
  $j = Start-Job { docker info --format '{{.NCPU}}|{{.MemTotal}}' 2>&1 }
  if(Wait-Job $j -Timeout 15){
    $v = ((Receive-Job $j) -join ' ').Trim()
    if($v -match '^\d+\|\d+$'){
      $p=$v -split '\|'
      $gb=[math]::Round(([int64]$p[1])/1GB,2)
      SayOk '15-engine' ("engine UP - " + $p[0] + " vCPU / " + $gb + " GB RAM")
      $ready=$true; break
    }
  }
  Stop-Job $j -EA SilentlyContinue; Remove-Job $j -Force -EA SilentlyContinue
}
if(-not $ready){ SayErr '15-engine' 'engine did not return after restart' }
else{
  SayOk '15-vm' ((Get-VM DockerDesktopVM | ForEach-Object { "DockerDesktopVM: " + $_.State + " " + [math]::Round($_.MemoryAssigned/1GB,1) + " GB" }) -join '')
  $u = docker ps -q 2>&1 | Measure-Object | Select-Object -ExpandProperty Count
  SayOk '15-containers' ("running containers: " + $u)
}
