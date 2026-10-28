$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36'
$embed = Invoke-WebRequest 'https://www.youtube.com/embed/240RfDRitx8' -UseBasicParsing -Headers @{ 'User-Agent' = $ua }
$key = [regex]::Match($embed.Content, '"INNERTUBE_API_KEY":"([^"]+)"').Groups[1].Value
Write-Output "key=$key"

$json = '{"context":{"client":{"clientName":"WEB_EMBEDDED_PLAYER","clientVersion":"1.20250101.00.00","clientScreen":"EMBED"}},"videoId":"240RfDRitx8","playbackContext":{"contentPlaybackContext":{"html5Preference":"HTML5_PREF_WANTS"}}}'

$h = @{
  'User-Agent'  = $ua
  'Content-Type' = 'application/json'
  'Origin'       = 'https://www.youtube.com'
  'Referer'      = 'https://www.youtube.com/embed/240RfDRitx8'
}
try {
  $r = Invoke-RestMethod -Uri "https://www.youtube.com/youtubei/v1/player?key=$key" -Method Post -Body $json -Headers $h -TimeoutSec 30
  Write-Output ("status = " + $r.playabilityStatus.status)
  Write-Output ("reason = " + $r.playabilityStatus.reason)
  Write-Output ("playableInEmbed = " + $r.playabilityStatus.playableInEmbed)
  Write-Output ("title = " + $r.videoDetails.title)
} catch {
  Write-Output "ERR $($_.Exception.Message)"
}
