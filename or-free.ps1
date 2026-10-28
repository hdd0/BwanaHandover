$m = (Invoke-RestMethod -Uri https://openrouter.ai/api/v1/models -TimeoutSec 30).data
$free = $m | Where-Object { [double]$_.pricing.prompt -eq 0 -and [double]$_.pricing.completion -eq 0 }
Write-Output "total models: $($m.Count)  free: $($free.Count)"
$free | Sort-Object id | ForEach-Object { "$($_.id)  ctx=$($_.context_length)" }
