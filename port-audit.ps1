$ports = @(3010,3015,3300,3100,4340,5173,3366,8081,3366)
foreach ($pt in $ports) {
  $c = Get-NetTCPConnection -LocalPort $pt -State Listen -ErrorAction SilentlyContinue
  if ($c) {
    foreach ($x in $c) { Write-Output ("PORT " + $pt + " LISTEN pid=" + $x.OwningProcess) }
  } else {
    Write-Output ("PORT " + $pt + " DEAD")
  }
}
Write-Output "---- surviving dev parents ----"
foreach ($id in @(6476,32192,35464,35864,33312,37180,21032,20648,20664,9012,18972,8704,10316,35032,20572,3428)) {
  $p = Get-Process -Id $id -ErrorAction SilentlyContinue
  if ($p) { Write-Output ("ALIVE " + $id + " " + $p.ProcessName) } else { Write-Output ("DEAD  " + $id) }
}
