$newParents = @(152348, 31844)
foreach ($id in $newParents) {
  $p = Get-Process -Id $id -ErrorAction SilentlyContinue
  if ($p) { Write-Output ("NEW PARENT ALIVE " + $id + " " + $p.ProcessName) } else { Write-Output ("NEW PARENT DEAD  " + $id) }
}
$children = Get-CimInstance Win32_Process -Filter "ParentProcessId=152348 OR ParentProcessId=31844" -ErrorAction SilentlyContinue
if ($children) {
  foreach ($c in $children) { Write-Output ("NEW CHILD " + $c.ProcessId + " " + $c.CommandLine) }
} else {
  Write-Output "NO NEW CHILDREN"
}