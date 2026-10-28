$ErrorActionPreference = 'Stop'
$initFile = 'C:\Users\howar\AppData\Local\Temp\opencode\openbao-init.out'
$keysFile = 'C:\STEP\architect-app\.openbao-init-keys'
$lines = Get-Content $initFile
$unsealKey = ($lines | Where-Object { $_ -match 'Unseal Key 1:' }) -replace '.*Unseal Key 1:\s*', ''
$rootToken = ($lines | Where-Object { $_ -match 'Initial Root Token:' }) -replace '.*Initial Root Token:\s*', ''
if (-not $unsealKey -or -not $rootToken) { throw 'Failed to parse init output' }
$keysContent = "OPENBAO_UNSEAL_KEY=$unsealKey`nOPENBAO_ROOT_TOKEN=$rootToken`n"
[System.IO.File]::WriteAllText($keysFile, $keysContent)
# Delete the raw init output
Remove-Item $initFile -Force
Write-Output 'Keys stored in gitignored file. Raw init output deleted.'
