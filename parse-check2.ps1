# parse-check2 - detailed
$f = 'dsc\DomainControllers\BwanaDC.ps1'
$tokens = $null
$errs = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errs)
Write-Output ("errors=" + $errs.Count)
foreach ($e in $errs) { Write-Output ($e.Message + " @line " + $e.Extent.StartLineNumber) }
Write-Output DONE2
