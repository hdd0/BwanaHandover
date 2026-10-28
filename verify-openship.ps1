$ErrorActionPreference = 'Continue'

$before = Get-Content 'C:\Users\howar\AppData\Local\Temp\opencode\baseline-before.json' -Raw | ConvertFrom-Json
$destRoot = 'C:\STEP\bwana-openship-standalone\_moved'

$map = @(
  @{ Src='C:\STEP\openship';                          Dst='openship' }
  @{ Src='C:\STEP\openship-platform';                  Dst='openship-platform' }
  @{ Src='C:\STEP\openship-architect-console';         Dst='openship-architect-console' }
  @{ Src='C:\STEP\openship-vmware-ops';                Dst='openship-vmware-ops' }
  @{ Src='C:\STEP\jenkins-openship';                   Dst='jenkins-openship' }
  @{ Src='C:\BwanaInfra\Bwana-OpenShip-VMware-K3s';   Dst='Bwana-OpenShip-VMware-K3s' }
)

function Get-TreeStat($path) {
  if (-not (Test-Path -LiteralPath $path)) {
    return [pscustomobject]@{ Files=0; Dirs=0; Bytes=[int64]0; Missing=$true }
  }
  # exclude junctions the same way robocopy /XJ did
  $files = Get-ChildItem -LiteralPath $path -Recurse -Force -File -ErrorAction SilentlyContinue |
             Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }
  $dirs  = Get-ChildItem -LiteralPath $path -Recurse -Force -Directory -ErrorAction SilentlyContinue |
             Where-Object { -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) }
  [pscustomobject]@{
    Files  = @($files).Count
    Dirs   = @($dirs).Count
    Bytes  = [int64](($files | Measure-Object -Property Length -Sum).Sum)
    Missing= $false
  }
}

$report = foreach ($m in $map) {
  $b = $before | Where-Object { $_.Source -eq $m.Src }
  $a = Get-TreeStat (Join-Path $destRoot $m.Dst)
  $fileMatch = ($a.Files  -eq $b.Files)
  $dirMatch  = ($a.Dirs   -eq $b.Dirs)
  $byteMatch = ($a.Bytes  -eq $b.Bytes)
  [pscustomobject]@{
    Folder        = $m.Dst
    Files_src     = $b.Files
    Files_dst     = $a.Files
    Files_ok      = $fileMatch
    Dirs_ok       = $dirMatch
    Bytes_src     = $b.Bytes
    Bytes_dst     = $a.Bytes
    Bytes_ok      = $byteMatch
    VERIFIED      = ($fileMatch -and $dirMatch -and $byteMatch)
  }
}

$report | Export-Csv -LiteralPath 'C:\Users\howar\AppData\Local\Temp\opencode\verify-report.csv' -NoTypeInformation -Encoding utf8
$report | Format-Table -AutoSize | Out-String -Width 250

Write-Output "=== SUMMARY ==="
$bad = @($report | Where-Object { -not $_.VERIFIED })
if ($bad.Count -eq 0) {
  "ALL {0} FOLDERS VERIFIED (file count, dir count, byte total all match)" -f @($report).Count
} else {
  "MISMATCH in: " + (($bad | ForEach-Object { $_.Folder }) -join ', ')
}
