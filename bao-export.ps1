$ErrorActionPreference = 'Stop'
$tok = ((Get-Content 'C:\STEP\architect-app\.env.secrets' -Raw | Select-String -Pattern 'OPENBAO_DEV_ROOT_TOKEN=(.+)').Matches.Groups[1].Value.Trim())
$env:VAULT_ADDR = 'http://127.0.0.1:8200'
function Bexec($a) { docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e "VAULT_TOKEN=$tok" architect-openbao bao @a 2>$null }
$paths = @()
$list = Bexec @('kv', 'list', '-format=json', 'secret/step/')
if ($list) { $paths = ($list | ConvertFrom-Json) }
# also check step/nas and any other top-level created paths
$all = @()
foreach ($p in $paths) {
  $full = "secret/step/$($p.TrimEnd('/'))"
  $all += $full
}
$export = @()
foreach ($fp in $all) {
  $j = Bexec @('kv', 'get', '-format=json', $fp)
  if ($j) {
    $d = ($j | ConvertFrom-Json).data.data
    $export += @{ path = $fp; data = $d }
    "EXPORTED $fp ($($d.PSObject.Properties.Count) fields)"
  }
}
$out = 'C:\Users\howar\AppData\Local\Temp\opencode\bao-export.json'
$export | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $out -Encoding UTF8
icacls $out /inheritance:r /grant:r "$($env:USERNAME):F" | Out-Null
"saved to $out (restricted ACL). paths: $($export.Count)"
