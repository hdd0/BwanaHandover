$apps = @('architect-platform','openship','cyberdeck','stride','.1','howard-cv-woven','bwanakhasu','step-store','local-search','howard-cv')
foreach($a in $apps){
  $p = "C:\STEP\$a"
  if(Test-Path $p){
    $pkgs = Get-ChildItem $p -Recurse -Depth 4 -Filter package.json -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch 'node_modules' } | Select-Object -ExpandProperty FullName
    $docker = @()
    foreach($k in $pkgs){ if(Test-Path (Join-Path (Split-Path $k) 'Dockerfile')){ $docker += $k } }
    [PSCustomObject]@{ App=$a; PkgJson=$pkgs.Count; HasDockerfile=($docker.Count) }
  } else { [PSCustomObject]@{ App=$a; PkgJson='MISSING'; HasDockerfile='' } }
}
