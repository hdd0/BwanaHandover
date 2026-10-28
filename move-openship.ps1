$ErrorActionPreference = 'Stop'

$dest = 'C:\STEP\bwana-openship-standalone'

$sources = @(
  'C:\STEP\openship',
  'C:\STEP\openship-platform',
  'C:\STEP\openship-architect-console',
  'C:\STEP\openship-vmware-ops',
  'C:\STEP\jenkins-openship',
  'C:\BwanaInfra\openship',
  'C:\BwanaInfra\Bwana-OpenShip-VMware-K3s'
)

function Get-TreeStat($path) {
  $files = Get-ChildItem -LiteralPath $path -Recurse -Force -File -ErrorAction SilentlyContinue
  $dirs  = Get-ChildItem -LiteralPath $path -Recurse -Force -Directory -ErrorAction SilentlyContinue
  [pscustomobject]@{
    Files = @($files).Count
    Dirs  = @($dirs).Count
    Bytes = [int64](($files | Measure-Object -Property Length -Sum).Sum)
  }
}

$baseline = foreach ($s in $sources) {
  if (Test-Path -LiteralPath $s) {
    $st = Get-TreeStat $s
    [pscustomobject]@{
      Source    = $s
      Name      = Split-Path $s -Leaf
      Exists    = $true
      Files     = $st.Files
      Dirs      = $st.Dirs
      Bytes     = $st.Bytes
      IsSymlink = [bool]((Get-Item -LiteralPath $s -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)
    }
  } else {
    [pscustomobject]@{ Source=$s; Name=(Split-Path $s -Leaf); Exists=$false; Files=0; Dirs=0; Bytes=0; IsSymlink=$false }
  }
}

$baseline | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath 'C:\Users\howar\AppData\Local\Temp\opencode\baseline-before.json' -Encoding utf8
$baseline | Format-Table -AutoSize | Out-String -Width 200
