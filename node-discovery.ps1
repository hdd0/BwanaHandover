$nodeIds = (Get-Process -Name node -ErrorAction SilentlyContinue).Id
Write-Host ('NODE-COUNT: ' + $nodeIds.Count)
$listeners = netstat -ano -p TCP | Select-String 'LISTENING'
foreach ($line in $listeners) {
  $parts = ($line.ToString().Trim() -split '\s+')
  $owner = $parts[-1]
  $local = $parts[1]
  foreach ($nid in $nodeIds) {
    if ([string]$nid -eq $owner) { Write-Host ('NODE-LISTENER pid=' + $owner + ' ' + $local) }
  }
}
Write-Host '---MODULE-PATHS---'
foreach ($nid in @(12596, 55908, 10316, 18972, 21032)) {
  try {
    $mods = (Get-Process -Id $nid -ErrorAction Stop).Modules | Select-Object -ExpandProperty FileName | Where-Object { $_ -match 'STEP|Users\\howar(?!.*(AppData|\\.vscode))|ProgramData' } | Select-Object -First 5
    Write-Host ('PID ' + $nid + ':')
    $mods | ForEach-Object { Write-Host ('  ' + $_) }
  } catch { Write-Host ('PID ' + $nid + ': unreadable (' + $_.Exception.Message + ')') }
}
Write-Host 'DISCOVERY-DONE'
