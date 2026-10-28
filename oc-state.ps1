Write-Output "--- CLI dir ---"
Get-ChildItem "$env:APPDATA\ai.opencode.desktop\cli" -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Output "--- data dir ---"
Get-ChildItem "$env:USERPROFILE\.local\share\opencode" -Filter *.db* -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Output "--- project_id references in opencode log (first 3 stack frames) ---"
Select-String -Path "$env:USERPROFILE\.local\share\opencode\log\opencode.log" -Pattern 'no such column: project_id' | Select-Object -First 1 | ForEach-Object { $_.Line.Substring(0,[Math]::Min(1200,$_.Line.Length)) }
