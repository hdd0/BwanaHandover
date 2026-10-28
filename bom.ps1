$f = "$env:APPDATA\Docker\settings-store.json"
$b = [System.IO.File]::ReadAllBytes($f)
"First 4 bytes: " + (($b[0..3] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
"BOM present  : " + ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
"Backup exists: " + (Test-Path "$f.bak-migrate")
$bb = [System.IO.File]::ReadAllBytes("$f.bak-migrate")
"Backup first4 : " + (($bb[0..3] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
