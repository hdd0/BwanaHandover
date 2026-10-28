$ErrorActionPreference = 'Stop'
$dest = 'C:\STEP\BwanaAI\BwanaAI\agents'
$staging = 'C:\Users\howar\AppData\Local\Temp\opencode\agents-staging'

if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

# ---------- 1. SKILLS ----------
$roots = @(
  @{ Name = 'shared-agents'; Path = 'C:\Users\howar\.agents\skills' },
  @{ Name = 'claude';        Path = 'C:\Users\howar\.claude\skills' },
  @{ Name = 'cursor';        Path = 'C:\Users\howar\.cursor\skills-cursor' },
  @{ Name = 'opencode';      Path = 'C:\Users\howar\.config\opencode\skill' }
)

$counts = @{}
foreach ($r in $roots) {
  if (-not (Test-Path $r.Path)) { continue }
  $target = Join-Path $staging "skills\$($r.Name)"
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  $dirs = Get-ChildItem $r.Path -Directory -ErrorAction SilentlyContinue
  foreach ($d in $dirs) {
    Copy-Item $d.FullName -Destination $target -Recurse -Force
  }
  # loose files (lock files, manifests, sync manifests)
  Get-ChildItem $r.Path -File -ErrorAction SilentlyContinue | Copy-Item -Destination $target -Force
  $counts[$r.Name] = @($dirs).Count
}

# shared agent hooks + manifests (.agents root, non-secret)
$agentsRoot = 'C:\Users\howar\.agents'
$hookDir = Join-Path $agentsRoot 'hooks'
if (Test-Path $hookDir) {
  New-Item -ItemType Directory -Path (Join-Path $staging 'hooks') -Force | Out-Null
  Copy-Item "$hookDir\*" -Destination (Join-Path $staging 'hooks') -Recurse -Force -ErrorAction SilentlyContinue
}

# ---------- 1b. STRIP BUILD/DEPS NOISE ----------
Get-ChildItem $staging -Recurse -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -in @('node_modules', '__pycache__', '.venv', '.git', 'dist', 'build') } |
  ForEach-Object { Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }

# ---------- 2. MCP CONFIGS (sanitised) ----------
$mcpDir = Join-Path $staging 'mcp'
New-Item -ItemType Directory -Path $mcpDir -Force | Out-Null

function Copy-Sanitised {
  param([string]$Source, [string]$Name, [string]$Note)
  if (-not (Test-Path $Source)) { return $false }
  $raw = Get-Content $Source -Raw
  # strip secrets (non-capturing key group so $2 stays the closing quote)
  $clean = $raw
  $clean = [regex]::Replace($clean, '(?i)("X-API-Key"\s*:\s*")[^"]*(")', '$1[REDACTED]$2')
  $clean = [regex]::Replace($clean, '(?i)("(?:api[_-]?key|apikey|token|secret|password|client[_-]?secret|auth[_-]?token|ANTHROPIC_AUTH_TOKEN)"\s*:\s*")[^"]*(")', '$1[REDACTED]$2')
  $clean = [regex]::Replace($clean, 'sk-[A-Za-z0-9_\-]{8,}', '[REDACTED]')
  $clean = [regex]::Replace($clean, 'gh[pousr]_[A-Za-z0-9]{20,}', '[REDACTED]')

  # a config that no longer parses is a broken restore - fail loudly instead
  if ($Name -like '*.json') {
    try { $null = $clean | ConvertFrom-Json }
    catch { throw "Sanitised output is not valid JSON: $Name - $($_.Exception.Message)" }
  }

  $header = "// SOURCE: $Source`r`n// NOTE: $Note`r`n"
  Set-Content -Path (Join-Path $mcpDir $Name) -Value ($header + $clean) -Encoding UTF8
  return $true
}

Copy-Sanitised 'C:\Users\howar\.config\opencode\opencode.json'      'opencode.json'            'Live OpenCode config. Credentials redacted.' | Out-Null
Copy-Sanitised 'C:\Users\howar\.config\opencode\opencode.jsonc'     'opencode.jsonc'           'OpenCode JSONC variant. Credentials redacted.' | Out-Null
Copy-Sanitised 'C:\Users\howar\.config\opencode\opencode.json.bak'  'opencode.json.bak'        'Previous OpenCode config. Credentials redacted.' | Out-Null
Copy-Sanitised 'C:\Users\howar\.config\opencode\opencode.jsonc.bak' 'opencode.jsonc.bak'       'Previous OpenCode JSONC. Credentials redacted.' | Out-Null
Copy-Sanitised 'C:\Users\howar\.cursor\mcp.json'                    'cursor-mcp.json'          'Cursor MCP servers.' | Out-Null
Copy-Sanitised 'C:\STEP\offline-mcp-servers\mcp.json'               'offline-mcp-servers.json' 'Offline Python MCP suite (filesystem, code-exec, docs, sqlite, search, KB).' | Out-Null
Copy-Sanitised 'C:\STEP\lmstudio-mcp-server\mcp.json'               'lmstudio-url-text-fetcher.json' 'LM Studio MCP server.' | Out-Null
Copy-Sanitised 'C:\STEP\lmstudio-mcp-server\mcp-with-brave.json'    'lmstudio-mcp-with-brave.json'   'LM Studio MCP + Brave search. Credentials redacted.' | Out-Null
Copy-Sanitised 'C:\STEP\BwanaAI\BwanaAI\opencode.json'              'bwanaai-opencode.json'    'Config bundled in this repo.' | Out-Null
Copy-Sanitised 'C:\Users\howar\.claude\settings.json'               'claude-settings.json'     'Claude Code settings incl. Orca hooks. Credentials redacted.' | Out-Null

# Claude MCP block extracted from .claude.json (never copy the whole file)
$claudeJson = 'C:\Users\howar\.claude\.claude.json'
if (Test-Path $claudeJson) {
  try {
    $obj = Get-Content $claudeJson -Raw | ConvertFrom-Json
    $servers = $obj.mcpServers
    if ($null -eq $servers) {
      $servers = [pscustomobject]@{ note = 'no global mcpServers key present; servers are per-project' }
    }
    $json = $servers | ConvertTo-Json -Depth 8
    $json = [regex]::Replace($json, '(?i)("(?:api[_-]?key|apikey|token|secret|password|client[_-]?secret)"\s*:\s*")[^"]*(")', '$1[REDACTED]$2')
    Set-Content -Path (Join-Path $mcpDir 'claude-mcp.json') -Value "// SOURCE: $claudeJson (mcpServers block only)`r`n$json" -Encoding UTF8
  } catch {
    Set-Content -Path (Join-Path $mcpDir 'claude-mcp.json') -Value "// SOURCE: $claudeJson`r`n// parse failed: $($_.Exception.Message)" -Encoding UTF8
  }
}

# ---------- 3. INVENTORY ----------
$now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss zzz')
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Agent Asset Inventory - NDIRANDEONE")
$lines.Add('')
$lines.Add("Generated: $now")
$lines.Add('')
$lines.Add('Machine-wide snapshot of every installed AI skill and MCP server configuration.')
$lines.Add('')
$lines.Add('## Skills')
$lines.Add('')
$lines.Add('| Source root | Install location | Skills |')
$lines.Add('|---|---|---|')
foreach ($r in $roots) {
  if ($counts.ContainsKey($r.Name)) {
    $lines.Add("| ``$($r.Name)`` | ``$($r.Path)`` | $($counts[$r.Name]) |")
  }
}
$lines.Add('')
$lines.Add('## MCP servers')
$lines.Add('')
$lines.Add('| Config | Location | Servers |')
$lines.Add('|---|---|---|')
function Get-McpNames {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return '(missing)' }
  try {
    $raw = Get-Content $Path -Raw
    if ($raw -match '^\s*//') { return 'see file' }
    $o = $raw | ConvertFrom-Json
    $names = @()
    if ($o.mcpServers) { $names += $o.mcpServers.PSObject.Properties.Name }
    if ($o.mcp) { $names += $o.mcp.PSObject.Properties.Name }
    if ($names.Count -eq 0) { return 'none' }
    return ($names -join ', ')
  } catch { return 'see file' }
}
$mcpMap = @(
  @{ L = 'C:\Users\howar\.config\opencode\opencode.json'; D = 'OpenCode (live)' },
  @{ L = 'C:\Users\howar\.config\opencode\opencode.jsonc'; D = 'OpenCode JSONC' },
  @{ L = 'C:\Users\howar\.cursor\mcp.json'; D = 'Cursor' },
  @{ L = 'C:\Users\howar\.claude\.claude.json'; D = 'Claude Code' },
  @{ L = 'C:\STEP\offline-mcp-servers\mcp.json'; D = 'Offline Python suite' },
  @{ L = 'C:\STEP\lmstudio-mcp-server\mcp.json'; D = 'LM Studio' },
  @{ L = 'C:\STEP\lmstudio-mcp-server\mcp-with-brave.json'; D = 'LM Studio + Brave' },
  @{ L = 'C:\STEP\BwanaAI\BwanaAI\opencode.json'; D = 'BwanaAI project' }
)
foreach ($m in $mcpMap) {
  $lines.Add("| $($m.D) | ``$($m.L)`` | $(Get-McpNames $m.L) |")
}
$lines.Add('')
$lines.Add('## Skill index (shared-agents root)')
$lines.Add('')
$sharedSkills = Get-ChildItem 'C:\Users\howar\.agents\skills' -Directory -ErrorAction SilentlyContinue | Sort-Object Name
foreach ($s in $sharedSkills) {
  $skillMd = Join-Path $s.FullName 'SKILL.md'
  $desc = ''
  if (Test-Path $skillMd) {
    $content = Get-Content $skillMd -Raw -Encoding UTF8
    if ($content -match '(?m)^description:\s*(.+)$') { $desc = $Matches[1].Trim() }
    elseif ($content -match '(?m)^#\s+(.+)$') { $desc = $Matches[1].Trim() }
  }
  if ($desc.Length -gt 150) { $desc = $desc.Substring(0, 147) + '...' }
  $lines.Add("- **$($s.Name)** - $desc")
}
$lines.Add('')
$lines.Add('## Secrets policy')
$lines.Add('')
$lines.Add('- API keys, tokens and passwords were stripped from every copied config (`[REDACTED]`).')
$lines.Add('- `.claude.json` is never copied wholesale; only its `mcpServers` block is exported.')
$lines.Add('- Paths use the original Windows locations so the bundle is reproducible on this host.')
Set-Content -Path (Join-Path $staging 'INVENTORY.md') -Value ($lines -join "`r`n") -Encoding UTF8

# export script, copied for reproducibility
Copy-Item -LiteralPath 'C:\Users\howar\AppData\Local\Temp\opencode\export-agents.ps1' -Destination (Join-Path $staging 'export-agents.ps1') -Force

# ---------- 4. SECRET SCAN + PUBLISH ----------
$hits = Get-ChildItem $staging -Recurse -File | Where-Object { $_.Name -ne 'export-agents.ps1' } | Select-String -Pattern 'sk-tinyfish-|L8Rp9M8t8O7f9C7s7t707An8zS56n9R9F6YRa7E7X|d914f1d0421d04500d9da18d00c6165b0ee767609bb5d05b67710306ecb08242|gho_[A-Za-z0-9]{20,}' -ErrorAction SilentlyContinue
if ($hits) {
  Write-Host 'SECRET LEAK BLOCKED:' -ForegroundColor Red
  $hits | ForEach-Object { Write-Host "  $($_.Path):$($_.LineNumber)" -ForegroundColor Red }
  exit 1
}
Write-Host 'Secret scan: clean' -ForegroundColor Green

if (Test-Path $dest) {
    # wipe generated content only - README.md is hand-maintained and must survive
    foreach ($sub in @('skills', 'mcp', 'hooks')) {
        $p = Join-Path $dest $sub
        if (Test-Path $p) { Remove-Item $p -Recurse -Force }
    }
    $inv = Join-Path $dest 'INVENTORY.md'
    if (Test-Path $inv) { Remove-Item $inv -Force }
    $exp = Join-Path $dest 'export-agents.ps1'
    if (Test-Path $exp) { Remove-Item $exp -Force }
    $nested = Join-Path $dest 'agents-staging'
    if (Test-Path $nested) { Remove-Item $nested -Recurse -Force }
}
else {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
}
# copy contents (never Move-Item onto an existing dir - that nests it)
Get-ChildItem $staging -Force | Copy-Item -Destination $dest -Recurse -Force
Remove-Item $staging -Recurse -Force

$files = (Get-ChildItem $dest -Recurse -File).Count
$mb = [math]::Round(((Get-ChildItem $dest -Recurse -File | Measure-Object Length -Sum).Sum / 1MB), 2)
Write-Host "Published $files files ($mb MB) to $dest" -ForegroundColor Green

