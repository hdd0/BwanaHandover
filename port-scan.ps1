$wanted = @(3000,3001,3010,3015,3020,3021,3050,3100,3300,3366,3367,3368,3369,4000,4100,4321,4331,4545,5050,5173,7070,8080,8081,8082,8085,8088,8089,8090,8091,8096,8100,8123,8200,8765,9001,9090,9222,11434,18789,26097,47831)
$listeners = netstat -ano -p TCP | Select-String 'LISTENING'
foreach ($line in $listeners) {
  $parts = ($line.ToString().Trim() -split '\s+')
  $local = $parts[1]
  $owner = $parts[-1]
  $port = ($local -split ':')[-1]
  foreach ($w in $wanted) {
    if ([string]$w -eq $port) {
      try { $pname = (Get-Process -Id $owner -ErrorAction Stop).ProcessName } catch { $pname = '?' }
      Write-Host ('PORT ' + $port + ' pid=' + $owner + ' (' + $pname + ') ' + $local)
    }
  }
}
Write-Host 'PORTSCAN-DONE'
