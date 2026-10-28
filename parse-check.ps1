$files = @(
  'C:\STEP\BwanaAD\scripts\promote-dc01.ps1',
  'C:\STEP\BwanaAD\scripts\promote-dc02.ps1',
  'C:\STEP\BwanaAD\scripts\backup-dc.ps1',
  'C:\STEP\BwanaAD\scripts\register-backup-task.ps1',
  'C:\STEP\BwanaAD\scripts\add-backup-volume.ps1',
  'C:\STEP\BwanaAD\scripts\apply-gpo-baseline.ps1',
  'C:\STEP\BwanaAD\scripts\enable-autologin.ps1',
  'C:\STEP\BwanaAD\dsc\ActiveDirectory\BwanaOU.ps1',
  'C:\STEP\BwanaAD\dsc\ActiveDirectory\BwanaGPO.ps1',
  'C:\STEP\BwanaAD\dsc\DomainControllers\BwanaDC.ps1'
)
$fail = 0
foreach ($f in $files) {
  $errs = $null
  [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)
  if ($errs.Count -eq 0) { Write-Output ("OK $f") }
  else { $fail++; Write-Output ("FAIL $f"); $errs | ForEach-Object { Write-Output ('  ' + $_.Message) } }
}
Write-Output ("RESULT failures=$fail")
