$ErrorActionPreference = 'Stop'
$keysFile = 'C:\STEP\architect-app\.openbao-init-keys'
$keys = @{}
Get-Content $keysFile | ForEach-Object {
  $parts = $_ -split '=', 2
  if ($parts.Count -eq 2) { $keys[$parts[0]] = $parts[1] }
}
$unsealKey = $keys['OPENBAO_UNSEAL_KEY']
if (-not $unsealKey) { throw 'Unseal key not found' }
docker exec -e BAO_ADDR=http://127.0.0.1:8200 architect-openbao bao operator unseal $unsealKey 2>&1 | Out-Null
Write-Output 'Unseal command executed.'
# Verify health
Start-Sleep -Seconds 2
docker exec -e BAO_ADDR=http://127.0.0.1:8200 architect-openbao bao status 2>&1 | Select-String 'Sealed|Initialized|Version' | ForEach-Object { $_.Line }
