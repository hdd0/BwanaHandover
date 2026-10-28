$ErrorActionPreference = 'Stop'
$tokFile = 'C:\STEP\architect-app\.env.secrets'
$tok = ((Get-Content -LiteralPath $tokFile -Raw) | Select-String -Pattern 'OPENBAO_DEV_ROOT_TOKEN=(.+)').Matches.Groups[1].Value.Trim()
$H = @{Authorization = "Bearer $tok" }
$sec = (Invoke-RestMethod 'http://127.0.0.1:8200/v1/secret/data/step/jenkins' -Headers $H -TimeoutSec 8).data.data
$user = [string]$sec.username
$pass = [string]$sec.admin_password
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$user`:$pass"))
$JH = @{Authorization = "Basic $pair" }
$base = 'http://127.0.0.1:8081'
$outDir = 'C:\Users\howar\AppData\Local\Temp\opencode'
$targets = @{
  'agent.json' = '/computer/windows-vmware/api/json?tree=displayName,offline,idle,numExecutors,assignedLabels[name],executors[currentExecutable[displayName]],systemInfo[os_name,os_version,os_arch]'
  'crumb.json' = '/crumbIssuer/api/json'
}
foreach ($k in $targets.Keys) {
  try {
    $r = Invoke-WebRequest -Uri ($base + $targets[$k]) -Headers $JH -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Set-Content -LiteralPath (Join-Path $outDir $k) -Value $r.Content -Encoding UTF8
    Add-Content -LiteralPath (Join-Path $outDir 'jnode.log') -Value ("OK $k len=" + $r.RawContentLength)
  } catch {
    Add-Content -LiteralPath (Join-Path $outDir 'jnode.log') -Value ("FAIL $k :: " + $_.Exception.Message)
  }
}
