$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'node'
$psi.Arguments = 'server.js'
$psi.WorkingDirectory = 'C:\STEP\local-search'
$psi.UseShellExecute = $false
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$psi.EnvironmentVariables['LOCAL_SEARCH_PORT'] = '3371'
$p = [System.Diagnostics.Process]::Start($psi)
Write-Host "started pid=$($p.Id)"
Start-Sleep -Seconds 40
$ls = Get-NetTCPConnection -State Listen -LocalPort 3371 -ErrorAction SilentlyContinue
if ($ls) { Write-Host "local-search up on 3371 pid=$($ls[0].OwningProcess)" } else { Write-Host 'STILL NOT UP' }
