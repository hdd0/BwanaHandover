$ErrorActionPreference = 'Stop'
$keysFile = 'C:\STEP\architect-app\.openbao-init-keys'
$keys = @{}
Get-Content $keysFile | ForEach-Object {
  $parts = $_ -split '=', 2
  if ($parts.Count -eq 2) { $keys[$parts[0]] = $parts[1] }
}
$rootToken = $keys['OPENBAO_ROOT_TOKEN']
$headers = @{ 'X-Vault-Token' = $rootToken }
# Create audit dir first
docker exec architect-openbao sh -c "mkdir -p /bao/data/audit && chown openbao:openbao /bao/data/audit" 2>&1 | Out-Null
# Try enabling audit
$body = '{"type":"file","options":{"file_path":"/bao/data/audit/audit.log"}}'
try {
  $r = Invoke-RestMethod -Uri 'http://127.0.0.1:8420/v1/sys/audit/file' -Method POST -Headers $headers -Body $body -ContentType 'application/json'
  Write-Output 'Audit device enabled.'
} catch {
  $resp = $_.Exception.Response
  $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
  $errBody = $reader.ReadToEnd()
  Write-Output ("HTTP {0}: {1}" -f $resp.StatusCode.value__, $errBody)
}
