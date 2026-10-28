$files = @("$env:USERPROFILE\.local\share\opencode\log\opencode.log", "$env:APPDATA\ai.opencode.desktop\logs\20261017T085415\main.log", "$env:APPDATA\ai.opencode.desktop\logs\20261017T085415\crash.log")
foreach ($f in $files) {
  Write-Output "=== $f ==="
  if (Test-Path $f) { Select-String -Path $f -Pattern 'Unexpected server error|~BUN|chunk-|jetbrains|ERROR|Error:' -CaseSensitive:$false | Select-Object -Last 12 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(300, $_.Line.Length)) } }
}
