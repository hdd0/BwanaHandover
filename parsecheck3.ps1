$errors = $null
$src = Get-Content -Raw 'C:\Users\howar\AppData\Local\Temp\opencode\bwana-phase1-elevated.ps1'
[void][System.Management.Automation.PSParser]::Tokenize($src, [ref]$errors)
Write-Output ("wrapper errors: " + $errors.Count)
foreach ($e in $errors) { Write-Output ($e.Message) }
