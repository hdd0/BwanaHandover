$ErrorActionPreference = "SilentlyContinue"
$results = @()
$paths = @("C:\STEP", "C:\Users\howar\.config", "C:\Users\howar\.agents", "C:\STEP\BwanaAI")
foreach ($p in $paths) {
  if (-not (Test-Path $p)) { continue }
  $files = Get-ChildItem -Path $p -Recurse -File -Include *.ps1,*.psm1,*.json,*.jsonc,*.md,*.txt,*.yml,*.yaml,*.py,*.js,*.ts,*.env* -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    if ($f.FullName -match "node_modules|\.git\\") { continue }
    try {
      $content = Get-Content $f.FullName -Raw
      if ($content -match "3366") {
        $results += [PSCustomObject]@{Path=$f.FullName}
      }
    } catch {}
  }
}
$results | Export-Csv -Path "C:\Users\howar\AppData\Local\Temp\opencode\files-3366.csv" -NoTypeInformation
$results | Format-Table -AutoSize
Write-Host "`nCOUNT: $($results.Count)" -ForegroundColor Cyan
