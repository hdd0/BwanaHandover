$ErrorActionPreference = "Continue"
$root = "C:\STEP\BWANA-OKD-Jenkins"
$tailLog = Join-Path $root ("logs\tail-stages-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
"TAIL START $(Get-Date -Format o)" | Set-Content $tailLog -Encoding utf8
$stages = @("stages\10-INTEGRATION-3366.ps1","stages\09-LB-QA.ps1","stages\12-FULL-DEPLOYMENT-TEST.ps1","stages\13-FINAL-HEALTH-CHECK.ps1")
foreach ($st in $stages) {
  ("===== " + $st + " =====") | Add-Content $tailLog -Encoding utf8
  $p = Join-Path $root $st
  $job = Start-Job -ScriptBlock { param($pp) & $pp; "TAIL_EXITCODE=$LASTEXITCODE" } -ArgumentList $p
  $done = Wait-Job $job -Timeout 90
  if (-not $done) {
    Stop-Job $job; Remove-Job $job -Force
    ("TIMEOUT 90s -- " + $st) | Add-Content $tailLog -Encoding utf8
  } else {
    $o = Receive-Job $job 2>&1 | ForEach-Object { "$_" }
    Remove-Job $job
    $o | Add-Content $tailLog -Encoding utf8
  }
}
"TAIL DONE $(Get-Date -Format o)" | Add-Content $tailLog -Encoding utf8
Write-Host ("TAIL LOG: " + $tailLog)