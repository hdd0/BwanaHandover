$files = @(
  'C:\STEP\BwanaAD\dsc\DomainControllers\BwanaDC.ps1',
  'C:\STEP\BwanaAD\scripts\bootstrap.ps1',
  'C:\STEP\BwanaAD\scripts\deploy.ps1',
  'C:\STEP\BwanaAD\scripts\test.ps1',
  'C:\STEP\BwanaAD\scripts\healthcheck.ps1'
)
foreach ($f in $files) {
  $errs = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)
  if ($errs.Count -eq 0) { Write-Output "SYNTAX-OK: $f" }
  else { Write-Output "SYNTAX-FAIL: $f"; $errs | ForEach-Object { Write-Output $_.Message } }
}
