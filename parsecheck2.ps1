$e2 = $null
$src2 = Get-Content -Raw 'C:\STEP\BwanaAD\dsc\DomainControllers\BwanaDC.ps1'
[void][System.Management.Automation.PSParser]::Tokenize($src2, [ref]$e2)
foreach ($e in $e2) { Write-Output ("LINE " + $e.Token.StartLine + " COL " + $e.Token.StartColumn + " : " + $e.Message) }
