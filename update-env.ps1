$ErrorActionPreference = 'Stop'
$keysFile = 'C:\STEP\architect-app\.openbao-init-keys'
$keys = @{}
Get-Content $keysFile | ForEach-Object {
  $parts = $_ -split '=', 2
  if ($parts.Count -eq 2) { $keys[$parts[0]] = $parts[1] }
}
$rootToken = $keys['OPENBAO_ROOT_TOKEN']
if (-not $rootToken) { throw 'Root token not found' }

# Update .env.secrets with new root token
$envFile = 'C:\STEP\architect-app\.env.secrets'
$envContent = Get-Content $envFile
$updated = $envContent | ForEach-Object {
  if ($_ -match '^OPENBAO_ROOT_TOKEN=') { "OPENBAO_ROOT_TOKEN=$rootToken" }
  elseif ($_ -match '^OPENBAO_UNSEAL_KEY=') { "OPENBAO_UNSEAL_KEY=$($keys['OPENBAO_UNSEAL_KEY'])" }
  else { $_ }
}
[System.IO.File]::WriteAllText($envFile, ($updated -join "`n") + "`n")

# Enable audit device via API
$headers = @{ 'X-Vault-Token' = $rootToken }
$body = '{"type":"file","options":{"file_path":"/bao/data/audit/audit.log"}}'
try {
  Invoke-RestMethod -Uri 'http://127.0.0.1:8420/v1/sys/audit/file' -Method POST -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
  Write-Output 'Audit device enabled.'
} catch {
  Write-Output ("Audit enable result: {0}" -f $_.Exception.Message)
}
Write-Output 'Done.'
