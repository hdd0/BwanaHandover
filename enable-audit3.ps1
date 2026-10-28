$ErrorActionPreference = 'Stop'
$keysFile = 'C:\STEP\architect-app\.openbao-init-keys'
$keys = @{}
Get-Content $keysFile | ForEach-Object {
  $parts = $_ -split '=', 2
  if ($parts.Count -eq 2) { $keys[$parts[0]] = $parts[1] }
}
$rootToken = $keys['OPENBAO_ROOT_TOKEN']
docker exec -e BAO_ADDR=http://127.0.0.1:8200 -e BAO_TOKEN=$rootToken architect-openbao bao audit enable file file_path=/bao/data/audit/audit.log 2>&1 | ForEach-Object { Write-Output $_ }
