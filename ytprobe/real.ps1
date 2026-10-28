$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36'

# Pull the real current client version + key straight from the watch page
$watch = Invoke-WebRequest 'https://www.youtube.com/watch?v=240RfDRitx8' -UseBasicParsing -Headers @{ 'User-Agent' = $ua; 'Accept-Language' = 'en-US,en;q=0.9' } -TimeoutSec 30
$ver = [regex]::Match($watch.Content, '"INNERTUBE_CLIENT_VERSION":"([^"]+)"').Groups[1].Value
$key = [regex]::Match($watch.Content, '"INNERTUBE_API_KEY":"([^"]+)"').Groups[1].Value
$visitor = [regex]::Match($watch.Content, '"visitorData":"([^"]+)"').Groups[1].Value
Write-Output "clientVersion=$ver"
Write-Output "key=$key"
Write-Output ("visitorData=" + $visitor.Substring(0, [Math]::Min(24, $visitor.Length)) + '...')

$embedded = [regex]::Match($watch.Content, '"playabilityStatus":\{"status":"([A-Z_]+)"').Groups[1].Value
$pIE = [regex]::Match($watch.Content, '"playableInEmbed":(true|false)').Groups[1].Value
Write-Output "watchpage playability=$embedded playableInEmbed=$pIE"

# Now ask the player API as WEB (not the broken probe client)
$body = '{"context":{"client":{"clientName":"WEB","clientVersion":"' + $ver + '","hl":"en","gl":"US","visitorData":"' + $visitor + '"},"user":{"lockedSafetyMode":false}},"videoId":"240RfDRitx8","contentCheckOk":true,"racyCheckOk":true}'
$h = @{ 'User-Agent' = $ua; 'Content-Type' = 'application/json'; 'Origin' = 'https://www.youtube.com'; 'Referer' = 'https://www.youtube.com/watch?v=240RfDRitx8' }

try {
  $r = Invoke-RestMethod -Uri "https://www.youtube.com/youtubei/v1/player?key=$key" -Method Post -Body $body -Headers $h -TimeoutSec 30
  Write-Output ("WEB player status = " + $r.playabilityStatus.status)
  Write-Output ("WEB player reason = " + $r.playabilityStatus.reason)
  Write-Output ("WEB title         = " + $r.videoDetails.title)
} catch {
  Write-Output "WEB player ERR $($_.Exception.Message)"
}
