Get-ScheduledTask -ErrorAction SilentlyContinue | ForEach-Object {
  $t = $_
  foreach ($a in $t.Actions) {
    $s = ($a.Execute + ' ' + $a.Arguments + ' ' + $a.WorkingDirectory)
    if ($s -match 'local-search|start\.bat|server\.js|C:\\STEP\\local') { "{0} | {1} | wd={2} | state={3}" -f $t.TaskName, ($a.Execute + ' ' + $a.Arguments), $a.WorkingDirectory, $t.State }
  }
}
'--- start.bat ---'
Get-Content 'C:\STEP\local-search\start.bat'
