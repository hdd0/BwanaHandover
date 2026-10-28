$ErrorActionPreference = 'Continue'

$dest = 'C:\STEP\bwana-openship-standalone\_moved'

# Source -> destination name. Leaf names are unique except the empty BwanaInfra\openship,
# which is left in place (nothing to copy) and reported separately.
$map = @(
  @{ Src = 'C:\STEP\openship';                            Dst = 'openship' }
  @{ Src = 'C:\STEP\openship-platform';                    Dst = 'openship-platform' }
  @{ Src = 'C:\STEP\openship-architect-console';           Dst = 'openship-architect-console' }
  @{ Src = 'C:\STEP\openship-vmware-ops';                  Dst = 'openship-vmware-ops' }
  @{ Src = 'C:\STEP\jenkins-openship';                     Dst = 'jenkins-openship' }
  @{ Src = 'C:\BwanaInfra\Bwana-OpenShip-VMware-K3s';     Dst = 'Bwana-OpenShip-VMware-K3s' }
)

New-Item -ItemType Directory -Path $dest -Force | Out-Null

$results = foreach ($m in $map) {
  $target = Join-Path $dest $m.Dst
  # /E = subdirs incl empty, /XJ = exclude junctions, /COPY:DAT = data+attrs+timestamps
  # /R:2 /W:2 = retry, /NFL /NDL /NJH /NJS /NP = quiet
  $log = Join-Path $env:TEMP ("rc-" + $m.Dst + ".log")
  & robocopy $m.Src $target /E /XJ /COPY:DAT /DCOPY:DAT /R:2 /W:2 /NFL /NDL /NJH /NP /MT:16 /LOG:$log
  $code = $LASTEXITCODE
  [pscustomobject]@{
    Source   = $m.Src
    Dest     = $target
    RobocopyExit = $code   # 0-7 = success, >=8 = failure
    Failed   = ($code -ge 8)
  }
  Write-Output ("{0,-52} rc={1}" -f $m.Dst, $code)
}

$results | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath 'C:\Users\howar\AppData\Local\Temp\opencode\copy-results.json' -Encoding utf8

Write-Output ""
Write-Output "=== any robocopy failures? ==="
$fail = @($results | Where-Object Failed)
if ($fail.Count -eq 0) { "NONE - all copies succeeded" } else { $fail | Format-Table -AutoSize | Out-String -Width 200 }
