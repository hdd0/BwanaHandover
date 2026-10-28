$ErrorActionPreference = 'SilentlyContinue'
try {
  $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8420/v1/sys/health' -UseBasicParsing -TimeoutSec 8
  Write-Output ("HTTP {0}: {1}" -f $r.StatusCode, $r.Content)
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  if ($code) { Write-Output ("HTTP {0}" -f $code) }
  else { Write-Output ("ERR: {0}" -f $_.Exception.Message) }
}
