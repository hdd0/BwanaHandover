$ids = @(55944,55620,48388,23132)
foreach ($id in $ids) {
  $p = Get-Process -Id $id -ErrorAction SilentlyContinue
  if ($p) { Write-Output ("PARENT ALIVE " + $id + " " + $p.ProcessName) } else { Write-Output ("PARENT DEAD  " + $id) }
}
$children = Get-CimInstance Win32_Process -Filter "ParentProcessId=55944 OR ParentProcessId=55620 OR ParentProcessId=48388 OR ParentProcessId=23132" -ErrorAction SilentlyContinue
if ($children) {
  foreach ($c in $children) { Write-Output ("CHILD " + $c.ProcessId + " " + $c.CommandLine) }
} else {
  Write-Output "NO CHILDREN FOUND via CIM"
}