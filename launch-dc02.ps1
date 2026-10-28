$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'powershell.exe'
$psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "C:\STEP\BwanaAD\scripts\promote-dc02.ps1" > "C:\STEP\BwanaAD\logs\promote-dc02.log" 2>&1'
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$p = [System.Diagnostics.Process]::Start($psi)
Write-Output ('LAUNCHED pid=' + $p.Id)
