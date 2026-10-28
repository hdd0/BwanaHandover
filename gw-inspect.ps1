foreach ($d in @("C:\STEP\gateway-3366","C:\STEP\step-ai-gateway")) {
  Write-Output "=== $d ==="
  if (Test-Path $d) {
    Get-ChildItem $d -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('node_modules','.git') } | Select-Object Name, Length | Format-Table -HideTableHeaders
    Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch '\\node_modules\\|\\.git\\' -and $_.Length -lt 512KB } | Select-String -Pattern 'gpt4all|lmstudio|LM Studio|ollama|openrouter|OPENAI_|providers' -CaseSensitive:$false | Select-Object -First 15 | ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim().Substring(0,[Math]::Min(200,$_.Line.Trim().Length)))" }
  }
}
Write-Output "=== gitignore/env presence ==="
Get-ChildItem "C:\STEP\gateway-3366","C:\STEP\step-ai-gateway" -Filter ".env*" -Force -ErrorAction SilentlyContinue | Select-Object FullName | Format-Table -HideTableHeaders
