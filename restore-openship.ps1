$ErrorActionPreference = 'Continue'

$src = 'C:\STEP\bwana-openship-standalone\_moved'

# Restore each repo to the exact path it was taken from.
$restore = @(
  @{ From = "$src\openship";                        To = 'C:\STEP\openship' }
  @{ From = "$src\openship-platform";                To = 'C:\STEP\openship-platform' }
  @{ From = "$src\openship-architect-console";       To = 'C:\STEP\openship-architect-console' }
  @{ From = "$src\openship-vmware-ops";              To = 'C:\STEP\openship-vmware-ops' }
  @{ From = "$src\jenkins-openship";                 To = 'C:\STEP\jenkins-openship' }
  @{ From = "$src\Bwana-OpenShip-VMware-K3s";       To = 'C:\BwanaInfra\Bwana-OpenShip-VMware-K3s' }
)

foreach ($r in $restore) {
  if (-not (Test-Path -LiteralPath $r.From)) { "SKIP (no longer at _moved)  $($r.To)"; continue }
  if (Test-Path -LiteralPath $r.To) { "BLOCKED - destination already exists  $($r.To)"; continue }
  try {
    Move-Item -LiteralPath $r.From -Destination $r.To -Force -ErrorAction Stop
    "RESTORED  $($r.To)"
  } catch {
    "FAILED    $($r.To)  ->  " + ($_.Exception.Message -replace '\s+',' ')
  }
}

Write-Output ""
Write-Output "=== verify: original paths present ==="
foreach ($r in $restore) { "{0,-48} exists={1}" -f $r.To, (Test-Path -LiteralPath $r.To) }
Write-Output ""
Write-Output "=== verify: _moved now empty of restored folders ==="
Get-ChildItem -LiteralPath $src -Force -ErrorAction SilentlyContinue | Select-Object Name | Format-Table -AutoSize | Out-String
