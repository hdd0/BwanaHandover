$ErrorActionPreference = 'Stop'
$keysFile = 'C:\STEP\architect-app\.openbao-init-keys'
$keys = @{}
Get-Content $keysFile | ForEach-Object {
  $parts = $_ -split '=', 2
  if ($parts.Count -eq 2) { $keys[$parts[0]] = $parts[1] }
}
$rootToken = $keys['OPENBAO_ROOT_TOKEN']
$headers = @{ 'X-Vault-Token' = $rootToken }
# Test token with a basic authenticated call
try {
  $r = Invoke-RestMethod -Uri 'http://127.0.0.1:8200/v1/sys/capabilities-self' -Method POST -Headers $headers -Body '{"paths":["sys/audit/*"]}' -ContentType 'application/json'
  Write-Output ("capabilities: {0}" -f ($r.capabilities -join ','))
} catch {
  Write-Output ("ERR: {0}" -f $_.Exception.Message)
}
# Check if .env.secrets was updated
$envContent = Get-Content 'C:\STEP\architect-app\.env.secrets'
$hasToken = ($envContent | Where-Object { $_ -match '^OPENBAO_ROOT_TOKEN=s\.' }) -ne $null
Write-Output ("env.secrets updated: {0}" -f $hasToken)
