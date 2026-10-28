$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/131.0 Safari/537.36'
$key = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8'

# control: dQw4w9WgXcQ is famously embeddable
$ids = @('240RfDRitx8', 'dQw4w9WgXcQ')

foreach ($id in $ids) {
  $body = '{"context":{"client":{"clientName":"WEB_EMBEDDED_PLAYER","clientVersion":"1.20250101.00.00","clientScreen":"EMBED","hl":"en"},"thirdParty":{"embedUrl":"http://127.0.0.1:5050/"}},"videoId":"' + $id + '"}'
  $h = @{
    'User-Agent'  = $ua
    'Content-Type' = 'application/json'
    'Origin'       = 'https://www.youtube.com'
    'Referer'      = 'http://127.0.0.1:5050/'
  }
  try {
    $r = Invoke-RestMethod -Uri "https://www.youtube.com/youtubei/v1/player?key=$key" -Method Post -Body $body -Headers $h -TimeoutSec 30
    Write-Output ("{0}  status={1}  reason={2}  title={3}" -f $id, $r.playabilityStatus.status, $r.playabilityStatus.reason, $r.videoDetails.title)
  } catch {
    Write-Output ("{0}  ERR {1}" -f $id, $_.Exception.Message)
  }
}
