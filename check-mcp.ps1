$mcp = 'C:\STEP\BwanaAI\BwanaAI\agents\mcp'
Get-ChildItem $mcp -Filter '*.json' | ForEach-Object {
    # strip our leading // comment header, then parse
    $raw = Get-Content $_.FullName -Raw
    $body = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
    try {
        $o = $body | ConvertFrom-Json
        $names = @()
        if ($o.mcpServers) { $names += $o.mcpServers.PSObject.Properties.Name }
        if ($o.mcp) { $names += $o.mcp.PSObject.Properties.Name }
        "{0,-32} OK   servers: {1}" -f $_.Name, ($(if ($names) { $names -join ',' } else { '(none)' }))
    } catch {
        "{0,-32} INVALID JSON: {1}" -f $_.Name, $_.Exception.Message
    }
}
'--- apiKey lines ---'
Select-String -Path (Join-Path $mcp '*.json'), (Join-Path $mcp '*.jsonc') -Pattern 'apiKey|AUTH_TOKEN|X-API-Key' | ForEach-Object { "$($_.Filename):$($_.LineNumber): $($_.Line.Trim())" }
