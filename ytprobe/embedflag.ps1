$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36'
$watch = Invoke-WebRequest 'https://www.youtube.com/watch?v=240RfDRitx8' -UseBasicParsing -Headers @{ 'User-Agent' = $ua } -TimeoutSec 30
$ver = [regex]::Match($watch.Content, '"INNERTUBE_CLIENT_VERSION":"([^"]+)"').Groups[1].Value
$key = [regex]::Match($watch.Content, '"INNERTUBE_API_KEY":"([^"]+)"').Groups[1].Value
$visitor = [regex]::Match($watch.Content, '"visitorData":"([^"]+)"').Groups[1].Value

# Ask specifically: is EMBEDDING allowed?  playabilityStatus.playableInEmbed is the flag
$body = '{"context":{"client":{"clientName":"WEB_EMBEDDED_PLAYER","clientVersion":"' + $ver + '","hl":"en","gl":"US","visitorData":"' + $visitor + '"},"thirdParty":{"embedUrl":"https://chewy-from-starting.ngrok-free.dev/"}},"videoId":"240RfDRitx8","contentCheckOk":true,"racyCheckOk":true}'
$h = @{ 'User-Agent' = $ua; 'Content-Type' = 'application/json'; 'Origin' = 'https://www.youtube.com'; 'Referer' = 'https://www.youtube.com/' }

try {
  $r = Invoke-RestMethod -Uri "https://www.youtube.com/youtubei/v1/player?key=$key" -Method Post -Body $body -Headers $h -TimeoutSec 30
  $ps = $r.playabilityStatus
  Write-Output ("EMBEDDED_PLAYER status      = " + $ps.status)
  Write-Output ("EMBEDDED_PLAYER reason      = " + $ps.reason)
  Write-Output ("EMBEDDED_PLAYER playableInEmbed = " + $ps.playableInEmbed)
  Write-Output ("videoDetails.title          = " + $r.videoDetails.title)
  Write-Output ("videoDetails.isLiveContent  = " + $r.videoDetails.isLiveContent)
  Write-Output ("streamingData present       = " + ($null -ne $r.streamingData))
  Write-Output ("microformat.category        = " + $r.microformat.playerMicroformatRenderer.category)
  Write-Output ("isFamilySafe                = " + $r.microformat.playerMicroformatRenderer.isFamilySafe)
} catch {
  Write-Output "ERR $($_.Exception.Message)"
}
