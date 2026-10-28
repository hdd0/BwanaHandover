Add-Type -AssemblyName System.Drawing
$src = New-Object System.Drawing.Bitmap 200,100
$g = [System.Drawing.Graphics]::FromImage($src)
$g.Clear([System.Drawing.Color]::Navy)
$g.Dispose()
$w = 100
$h = 50
$small = New-Object System.Drawing.Bitmap $w, $h
$g2 = [System.Drawing.Graphics]::FromImage($small)
$g2.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g2.DrawImage($src, 0, 0, $w, $h)
$g2.Dispose()
$src.Dispose()
$out = Join-Path $env:TEMP 'opencode\amsi-test.jpg'
$small.Save($out, [System.Drawing.Imaging.ImageFormat]::Jpeg)
$small.Dispose()
Write-Host "ok $out $((Get-Item $out).Length) bytes"
