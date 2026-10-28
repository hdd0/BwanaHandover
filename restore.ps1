. C:\STEP\docker-migration\log3366.ps1
$env:BWANA_DEP_ID='MIGRATE-DOCKER-20261010-103850'
$f = "$env:APPDATA\Docker\settings-store.json"
$b = "$f.bak-migrate"

SayStart '08-restore' 'PS5.1 ConvertTo-Json destroyed settings-store.json (1029->104 bytes). Restoring backup.'
Copy-Item $b $f -Force
$j = [System.IO.File]::ReadAllText($f) | ConvertFrom-Json
SayOk '08-restored' ("restored " + (Get-Item $f).Length + " bytes / " + ($j.PSObject.Properties.Name).Count + " keys")

SayStart '09-targeted-edit' 'Switching backend via targeted string replace (no JSON round-trip)'
$txt = [System.IO.File]::ReadAllText($f)
if($txt -match '"wslEngineEnabled"\s*:\s*true'){
  $txt = $txt -replace '("wslEngineEnabled"\s*:\s*)true', '$1false'
  [System.IO.File]::WriteAllText($f, $txt, (New-Object System.Text.UTF8Encoding($false)))
  SayOk '09-switched' 'wslEngineEnabled true -> false'
} elseif($txt -match '"wslEngineEnabled"\s*:\s*false'){
  SayWarn '09-switched' 'wslEngineEnabled was already false'
} else {
  SayWarn '09-switched' 'wslEngineEnabled key not found in settings - manual check needed'
}
$after = [System.IO.File]::ReadAllText($f)
$afterJ = $after | ConvertFrom-Json
SayOk '09-verify' ("size=" + (Get-Item $f).Length + " keys=" + ($afterJ.PSObject.Properties.Name).Count + " wslEngineEnabled=" + $afterJ.wslEngineEnabled + " BOM=" + ([System.IO.File]::ReadAllBytes($f)[0] -eq 0xEF))
