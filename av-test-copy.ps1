Add-Type -AssemblyName System.Drawing
$b = New-Object System.Drawing.Bitmap 100,100
$g = [System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen(0,0,0,0,$b.Size)
$g.Dispose()
Write-Host 'copy-from-screen OK'
