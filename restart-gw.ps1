Stop-Process -Id 32976 -Force -ErrorAction SilentlyContinue
Stop-Process -Id 60344 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 12
$l = Get-NetTCPConnection -State Listen -LocalPort 3366 -ErrorAction SilentlyContinue
if ($l) { "3366 respawned by task: pid=$($l[0].OwningProcess)" } else { 'no respawn on 3366 - starting manually'; $g = Start-Process -FilePath 'node' -ArgumentList 'server.js' -WorkingDirectory 'C:\STEP\gateway-3366' -WindowStyle Hidden -PassThru; "gateway pid=$($g.Id)" }
$a = Start-Process -FilePath 'node' -ArgumentList 'atomic-proxy.js' -WorkingDirectory 'C:\STEP\gateway-3366' -WindowStyle Hidden -PassThru
"atomic pid=$($a.Id)"
Start-Sleep -Seconds 4
Get-NetTCPConnection -State Listen -LocalPort 3366,3369,3371,1337 -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess | Format-Table -AutoSize
