# verify wrapper parses under 5.1
$f = 'scripts\build-elevated.ps1'
$tokens = $null
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errs)
Write-Output ("errors=" + $errs.Count)
foreach ($e in $errs) { Write-Output $e.Message }
Write-Output DONE3
