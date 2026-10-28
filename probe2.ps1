$ErrorActionPreference = 'SilentlyContinue'
$targets = @(
  @{n='3366 /api/health'; u='http://127.0.0.1:3366/api/health'},
  @{n='3366 /api/services'; u='http://127.0.0.1:3366/api/services'},
  @{n='openbao /v1/sys/health'; u='http://127.0.0.1:8420/v1/sys/health?standbyok=true'}
)
foreach ($t in $targets) {
  try {
    $r = Invoke-WebRequest -Uri $t.u -UseBasicParsing -TimeoutSec 8
    Write-Output ("--- {0} => HTTP {1} ---" -f $t.n, $r.StatusCode)
    Write-Output $r.Content
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code) { Write-Output ("--- {0} => HTTP {1} ---" -f $t.n, $code) }
    else { Write-Output ("--- {0} => FAIL {1} ---" -f $t.n, $_.Exception.Message) }
  }
  Write-Output ""
}
