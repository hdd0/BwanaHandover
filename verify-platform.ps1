$ErrorActionPreference = 'Continue'
$root = 'C:\STEP\BwanaPlatform'

function Section($t) { Write-Output ""; Write-Output "=== $t ===" }

Section 'WORKSPACE ARTIFACTS'
foreach ($f in @('BwanaPlatform.sln','BwanaPlatform.code-workspace')) {
  $p = Join-Path $root $f
  "{0,-35} exists={1}" -f $f, (Test-Path $p)
}

Section 'GIT DELETED / MODIFIED'
& git -C $root status --short

Section 'RESUME SCRIPTS (present on disk)'
Get-ChildItem -Path $root -Filter '*Resume*.ps1' -File -ErrorAction SilentlyContinue |
  ForEach-Object { "{0,-45} {1,8} bytes  {2}" -f $_.Name, $_.Length, $_.LastWriteTime }

Section 'DOCS / PLANS'
if (Test-Path (Join-Path $root 'docs\superpowers')) {
  Get-ChildItem -Path (Join-Path $root 'docs\superpowers') -Recurse -File |
    ForEach-Object { "{0}  ({1} bytes)" -f $_.FullName.Replace($root,'.'), $_.Length }
} else { 'no docs\superpowers' }

Section 'AI SOURCES - local ports'
$ports = 3366, 11434, 1234, 8080, 5000, 5001, 8000, 9222, 3000, 11435
$listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue
foreach ($p in $ports) {
  $hit = $listeners | Where-Object { $_.LocalPort -eq $p } | Select-Object -First 1
  if ($hit) {
    $proc = try { (Get-Process -Id $hit.OwningProcess -ErrorAction SilentlyContinue).ProcessName } catch { '?' }
    "port {0,-6} LISTEN  pid={1,-8} proc={2}" -f $p, $hit.OwningProcess, $proc
  } else {
    "port {0,-6} closed" -f $p
  }
}

Section 'HTTP PROBES'
foreach ($u in @('http://127.0.0.1:3366/','http://127.0.0.1:11434/api/tags','http://127.0.0.1:1234/v1/models','http://127.0.0.1:5000/v1/models')) {
  try {
    $r = Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    "{0,-42} HTTP {1}  len={2}" -f $u, $r.StatusCode, $r.RawContentLength
  } catch {
    "{0,-42} DOWN  ({1})" -f $u, $_.Exception.Message.Split([Environment]::NewLine)[0]
  }
}

Section 'DOCKER'
try { & docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' } catch { 'docker unavailable' }

Section 'OPENCODE CONFIG - model/provider hints'
$cfg = Join-Path $env:USERPROFILE '.config\opencode\opencode.json'
if (Test-Path $cfg) {
  "config: $cfg"
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  "providers:"
  $j.provider.PSObject.Properties.Name | ForEach-Object { "  - $_" }
} else { "no opencode.json at $cfg" }
