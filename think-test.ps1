$body = @{ model='qwen3:0.6b'; messages=@(@{role='user';content='Reply with exactly: OK'}); stream=$false; think=$false } | ConvertTo-Json -Depth 4
$sw=[Diagnostics.Stopwatch]::StartNew()
$r = Invoke-WebRequest 'http://127.0.0.1:11434/api/chat' -Method POST -ContentType 'application/json' -Body $body -UseBasicParsing -TimeoutSec 120
$sw.Stop()
$j = $r.Content | ConvertFrom-Json
"HTTP $($r.StatusCode) in $([math]::Round($sw.Elapsed.TotalSeconds,1))s"
"content=[$($j.message.content)]"
"thinking_present=$([bool]$j.message.thinking)"
