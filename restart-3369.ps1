Stop-Process -Id 48728 -Force -ErrorAction SilentlyContinue
Stop-Process -Id 14044 -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$env:LOCAL_SEARCH_PORT = '3371'
$ls = Start-Process -FilePath 'node' -ArgumentList 'server.js' -WorkingDirectory 'C:\STEP\local-search' -WindowStyle Hidden -PassThru
$env:LOCAL_SEARCH_PORT = $null
$ed = Start-Process -FilePath 'node' -ArgumentList 'C:\STEP\gateway-3366\virtual-display-server.js' -WorkingDirectory 'C:\STEP\gateway-3366' -WindowStyle Hidden -PassThru
"local-search pid=$($ls.Id)  edge pid=$($ed.Id)"
