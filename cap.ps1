. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
$f = "$env:APPDATA\Docker\settings-store.json"
Copy-Item $f "$f.bak-caps" -Force
$txt = [System.IO.File]::ReadAllText($f)

SayStart '14-resource-caps' "Setting Docker ceiling to 12GB / 6 vCPU (of 63.7GB host, 25GB already on BWANA VMs)"

function Set-Key([string]$t, [string]$key, [string]$val){
  if($t -match ('"' + [regex]::Escape($key) + '"\s*:\s*[^,\r\n}]+')){
    return ($t -replace ('("' + [regex]::Escape($key) + '"\s*:\s*)[^,\r\n}]+'), ('$1' + $val))
  }
  # key absent -> insert after the opening brace
  return ($t -replace '(\{\s*\r?\n)', ('$1  "' + $key + '": ' + $val + ',' + [Environment]::NewLine))
}

$txt = Set-Key $txt 'memoryMiB' '12288'
$txt = Set-Key $txt 'cpus' '6'
[System.IO.File]::WriteAllText($f, $txt, (New-Object System.Text.UTF8Encoding($false)))

$j = [System.IO.File]::ReadAllText($f) | ConvertFrom-Json
$n = ($j.PSObject.Properties.Name).Count
SayOk '14-written' ("keys=" + $n + " memoryMiB=" + $j.memoryMiB + " cpus=" + $j.cpus + " bytes=" + (Get-Item $f).Length)
if($n -lt 20){ SayErr '14-written' 'key count collapsed - aborting before restart' }
