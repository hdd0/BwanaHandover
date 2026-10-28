$ErrorActionPreference = 'Stop'
$addr = 'http://127.0.0.1:8420'
function Bexec($a) { docker exec -e VAULT_ADDR=http://127.0.0.1:8200 architect-openbao bao @a 2>&1 }
$init = Bexec @('operator', 'init', '-key-shares=1', '-key-threshold=1', '-format=json')
$ij = $init | ConvertFrom-Json
$unseal = $ij.unseal_keys_b64[0]
$root = $ij.root_token
"init done (keys captured, not shown)"
Bexec @('operator', 'unseal', $unseal) | Out-Null
"unsealed"
$env:BAO_TOKEN = $root
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e "VAULT_TOKEN=$root" architect-openbao bao secrets enable -path=secret kv-v2 2>&1 | Select-Object -First 2
docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e "VAULT_TOKEN=$root" architect-openbao bao audit enable file file_path=/bao/logs/audit.log 2>&1 | Select-Object -First 2
"kv + audit enabled"
@("OPENBAO_ROOT_TOKEN=$root", "OPENBAO_UNSEAL_KEY=$unseal") | Set-Content -LiteralPath 'C:\STEP\architect-app\.env.secrets' -Encoding ASCII
".env.secrets rotated (root + unseal, values not shown)"
$env:BAO_TOKEN = $null
