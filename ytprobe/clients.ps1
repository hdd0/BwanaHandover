$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36'
$key = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8'

$clients = @(
  @{ name = 'WEB';           body = '{"context":{"client":{"clientName":"WEB","clientVersion":"2.20250101.00.00","clientScreen":"DESKTOP"}},"videoId":"240RfDRitx8"}' }
  @{ name = 'ANDROID';       body = '{"context":{"client":{"clientName":"ANDROID","clientVersion":"19.09.37","androidSdkVersion":30,"clientScreen":"MOBILE"}},"videoId":"240RfDRitx8"}' }
  @{ name = 'WEB_EMBEDDED';  body = '{"context":{"client":{"clientName":"WEB_EMBEDDED_PLAYER","clientVersion":"1.20250101.00.00","clientScreen":"EMBED"}},"videoId":"240RfDRitx8"}' }
)

foreach ($c in $clients) {
  $h = @{
    'User-Agent'  = $ua
    'Content-Type' = 'application/json'
    'Origin'       = 'https://www.youtube.com'
    'Referer'      = 'https://www.youtube.com/'
  }
  try {
    $r = Invoke-RestMethod -Uri "https://www.youtube.com/youtubei/v1/player?key=$key" -Method Post -Body $c.body -Headers $h -TimeoutSec 30
    Write-Output ("{0,-14} status={1} reason={2} title={3}" -f $c.name, $r.playabilityStatus.status, $r.playabilityStatus.reason, $r.videoDetails.title)
  } catch {
    Write-Output ("{0,-14} ERR {1}" -f $c.name, $_.Exception.Message)
  }
}
