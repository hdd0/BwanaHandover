$ErrorActionPreference = 'Stop'
$repo = 'hdd0/BwanaAI'
$out = 'C:\Users\howar\AppData\Local\Temp\opencode\remote'
New-Item -ItemType Directory -Path $out -Force | Out-Null

'=== remote HEAD ==='
git -C 'C:\STEP\BwanaAI\BwanaAI' log --oneline -1 origin/main

'=== agents/ contents on GitHub ==='
gh api "repos/$repo/contents/agents" --jq '.[] | .type + "  " + .name'

'=== mcp/ contents on GitHub ==='
gh api "repos/$repo/contents/agents/mcp" --jq '.[] | .name'

'=== downloading + validating sanitised configs ==='
foreach ($f in 'opencode.json', 'claude-settings.json', 'cursor-mcp.json', 'offline-mcp-servers.json') {
    $b64 = gh api "repos/$repo/contents/agents/mcp/$f" --jq '.content'
    $local = Join-Path $out $f
    [IO.File]::WriteAllBytes($local, [Convert]::FromBase64String($b64))
    $raw = Get-Content $local -Raw
    $body = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
    try {
        $null = $body | ConvertFrom-Json
        $verdict = 'VALID JSON'
    } catch {
        $verdict = "INVALID: $($_.Exception.Message)"
    }
    '{0,-30} {1}' -f $f, $verdict
}

'=== secret check on remote copies ==='
$bad = Get-ChildItem $out -File | Select-String -Pattern 'sk-tinyfish-|L8Rp9M8t8O7f9C7s7t707An8zS56n9R9F6YRa7E7X|gho_[A-Za-z0-9]{20,}'
if ($bad) { $bad | ForEach-Object { "LEAK: $($_.Filename):$($_.LineNumber)" } } else { 'clean' }

'=== redacted values as published ==='
Get-ChildItem $out -File | Select-String -Pattern 'REDACTED' | ForEach-Object { "$($_.Filename):$($_.LineNumber): $($_.Line.Trim())" }
