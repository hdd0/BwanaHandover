foreach ($id in @(13136,35800,36720,37180,21032,32192,33312,35464,6476)) {
  $p = Get-Process -Id $id -ErrorAction SilentlyContinue
  if ($p) { Write-Output ("ALIVE " + $id + " " + $p.ProcessName + " " + $p.StartTime) } else { Write-Output ("DEAD  " + $id) }
}
