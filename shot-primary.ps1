Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Get-Process vmconnect -ErrorAction SilentlyContinue | Select-Object Id,MainWindowTitle | Format-Table -AutoSize | Out-String | Write-Output
$b = [System.Windows.Forms.Screen]::AllScreens | Where-Object { $_.Primary } | Select-Object -First 1
$r = $b.Bounds
$bmp = New-Object System.Drawing.Bitmap($r.Width,$r.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Location,[System.Drawing.Point]::Empty,$r.Size)
$out='C:\STEP\BwanaAD\logs\golden-vm-primary-20261008.png'
$bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Get-Item $out | Select-Object FullName,Length
