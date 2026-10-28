$ErrorActionPreference = 'SilentlyContinue'

Write-Output "=== PID MAP (listening TCP) ==="
$conns = Get-NetTCPConnection -State Listen
$procIds = $conns | Select-Object -ExpandProperty OwningProcess -Unique | Sort-Object
foreach ($p in $procIds) {
  $proc = Get-Process -Id $p
  $pname = if ($proc) { $proc.ProcessName } else { '?' }
  $ports = ($conns | Where-Object { $_.OwningProcess -eq $p } | Select-Object -ExpandProperty LocalPort -Unique | Sort-Object) -join ','
  Write-Output ("PID {0,-8} {1,-30} ports: {2}" -f $p, $pname, $ports)
}

Write-Output ""
Write-Output "=== HTTP PROBES ==="
function Probe($name, $url) {
  try {
    $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 6
    Write-Output ("{0,-28} => HTTP {1} len={2}" -f $name, $r.StatusCode, $r.RawContentLength)
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code) { Write-Output ("{0,-28} => HTTP {1} (error response)" -f $name, $code) }
    else { Write-Output ("{0,-28} => FAIL {1}" -f $name, $_.Exception.Message) }
  }
}
Probe '3366 root'            'http://127.0.0.1:3366/'
Probe '3366 api/health'      'http://127.0.0.1:3366/api/health'
Probe '3366 api/services'    'http://127.0.0.1:3366/api/services'
Probe '3367 step-ai-gateway' 'http://127.0.0.1:3367/'
Probe '3368'                 'http://127.0.0.1:3368/'
Probe '3370 bwana-start'     'http://127.0.0.1:3370/'
Probe '3000'                 'http://127.0.0.1:3000/'
Probe '3001'                 'http://127.0.0.1:3001/'
Probe '3002'                 'http://127.0.0.1:3002/'
Probe '3003'                 'http://127.0.0.1:3003/'
Probe '3010'                 'http://127.0.0.1:3010/'
Probe '3015'                 'http://127.0.0.1:3015/'
Probe '3021'                 'http://127.0.0.1:3021/'
Probe '3052 pop-planner'     'http://127.0.0.1:3052/'
Probe '3100 loki?'           'http://127.0.0.1:3100/ready'
Probe '3300'                 'http://127.0.0.1:3300/'
Probe '4000'                 'http://127.0.0.1:4000/'
Probe '5050 cv-site'         'http://127.0.0.1:5050/'
Probe '5173 vite'            'http://127.0.0.1:5173/'
Probe '8080 vaultwarden'     'http://127.0.0.1:8080/alive'
Probe '8081 jenkins'         'http://127.0.0.1:8081/login'
Probe '8086 stalwart-admin'  'http://127.0.0.1:8086/'
Probe '8088'                 'http://127.0.0.1:8088/'
Probe '8096 jellyfin'        'http://127.0.0.1:8096/health'
Probe '8420 openbao-health'  'http://127.0.0.1:8420/v1/sys/health?standbyok=true'
Probe '9000'                 'http://127.0.0.1:9000/'
Probe '903'                  'http://127.0.0.1:903/'
Probe '911'                  'http://127.0.0.1:911/'
Probe '913'                  'http://127.0.0.1:913/'
Probe '11434 ollama'         'http://127.0.0.1:11434/api/tags'
Probe '13305'                'http://127.0.0.1:13305/'
Probe '80 http.sys'          'http://127.0.0.1:80/'
Probe '8443 http.sys'        'https://127.0.0.1:8443/'

Write-Output ""
Write-Output "=== HYPERV: BWANA-MAIL-01 ==="
$vm = Get-VM -Name 'BWANA-MAIL-01'
$vm | Select-Object Name,State,Uptime,Status,ProcessorCount,MemoryAssigned,Version | Format-List | Out-String -Width 200
$vm.NetworkAdapters | Select-Object Name,SwitchName,IPAddresses,Status | Format-List | Out-String -Width 200
$vm.HardDrives | Select-Object ControllerLocation,Path | Format-List | Out-String -Width 250
Write-Output "--- all VMs summary ---"
Get-VM | Select-Object Name,State,Uptime,Status | Format-Table -AutoSize | Out-String -Width 200

Write-Output ""
Write-Output "=== SERVICES (running, non-Windows paths) ==="
Get-CimInstance Win32_Service | Where-Object { $_.State -eq 'Running' -and $_.PathName -notmatch '\\Windows\\|Microsoft' } | Select-Object Name,DisplayName,StartMode | Format-Table -AutoSize | Out-String -Width 200

Write-Output ""
Write-Output "=== SCHEDULED TASKS (matching keywords) ==="
Get-ScheduledTask | Where-Object { $_.TaskName -match 'bwana|opencode|jenkins|openship|gateway|3366|stalwart|vault|mail|resume' } | Select-Object TaskName,State,TaskPath | Format-Table -AutoSize | Out-String -Width 220

Write-Output ""
Write-Output "=== KUBECTL (docker-desktop) ==="
kubectl get nodes 2>&1 | Out-String -Width 200
kubectl get pods -A 2>&1 | Select-Object -First 30 | Out-String -Width 220

Write-Output ""
Write-Output "=== DISK SPACE ==="
Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{n='UsedGB';e={[math]::Round($_.Used/1GB,1)}},@{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}} | Format-Table -AutoSize | Out-String -Width 120
