Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$shotsDir = 'C:\STEP\BwanaAI\BwanaAI\dev\screenshots'
New-Item -ItemType Directory -Path $shotsDir -Force | Out-Null

foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
    $b = $screen.Bounds
    $name = ($screen.DeviceName -replace '[\\.]', '_')
    $path = Join-Path $shotsDir ("{0}-{1}-{2}x{3}.png" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $name, $b.Width, $b.Height)
    $bmp = New-Object System.Drawing.Bitmap($b.Width, $b.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "Screenshot: $path ($($b.Width)x$($b.Height) at $($b.X),$($b.Y)) primary=$($screen.Primary)"
}
