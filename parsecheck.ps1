$errors = $null
$src1 = Get-Content -Raw 'C:\STEP\BwanaAD\scripts\deploy.ps1'
[void][System.Management.Automation.PSParser]::Tokenize($src1, [ref]$errors)
Write-Output ("deploy errors: " + $errors.Count)
if ($errors) { $errors | Select-Object -First 5 | Format-List }
$e2 = $null
$src2 = Get-Content -Raw 'C:\STEP\BwanaAD\dsc\DomainControllers\BwanaDC.ps1'
[void][System.Management.Automation.PSParser]::Tokenize($src2, [ref]$e2)
Write-Output ("dsc errors: " + $e2.Count)
