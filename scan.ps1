$root = 'C:\STEP'
$all = @()
# Top-level
$top = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
# Also one level deep
$candidates = @()
foreach ($t in $top) {
  $candidates += $t.FullName
  $sub = Get-ChildItem -Path $t.FullName -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'node_modules' -and $_.Name -ne '.git' }
  foreach ($s in $sub) { $candidates += $s.FullName }
}
# dedupe
$candidates = $candidates | Select-Object -Unique
foreach ($full in $candidates) {
  if (-not (Test-Path (Join-Path $full '.git'))) { continue }
  $rel = $full.Substring($root.Length+1)
  try { $branch = (git -C $full rev-parse --abbrev-ref HEAD 2>$null) } catch { $branch = '?' }
  if (-not $branch) { $branch = '?' }
  $remote = (git -C $full remote get-url origin 2>$null)
  if (-not $remote) { $remote = '(no origin)' }
  $porcelain = (git -C $full status --porcelain 2>$null)
  $dirty = if ($porcelain) { 'DIRTY' } else { 'clean' }
  $handover = 'no'
  if (Test-Path (Join-Path $full 'docs\AI_HANDOVER.md')) { $handover = 'AI_HANDOVER.md' }
  elseif (Test-Path (Join-Path $full 'AI_HANDOVER.md')) { $handover = 'AI_HANDOVER.md' }
  elseif (Test-Path (Join-Path $full 'HANDOVER.md')) { $handover = 'HANDOVER.md' }
  $lastCommit = (git -C $full log -1 --format='%ci|%s' 2>$null)
  $all += [pscustomobject]@{
    Path=$rel; Branch=$branch; Dirty=$dirty; Handover=$handover; Remote=$remote; LastCommit=$lastCommit
  }
}
$all | Sort-Object Path | Export-Csv -Path 'C:\Users\howar\AppData\Local\Temp\opencode\scan.csv' -NoTypeInformation
Write-Host "COUNT: $($all.Count)"
