$ErrorActionPreference = 'Stop'
$tokFile = 'C:\STEP\architect-app\.env.secrets'
$tok = ((Get-Content -LiteralPath $tokFile -Raw) | Select-String -Pattern 'OPENBAO_DEV_ROOT_TOKEN=(.+)').Matches.Groups[1].Value.Trim()
$H = @{Authorization = "Bearer $tok" }
$sec = (Invoke-RestMethod 'http://127.0.0.1:8200/v1/secret/data/step/jenkins' -Headers $H -TimeoutSec 8).data.data
$user = [string]$sec.username
$pass = [string]$sec.admin_password
$pair = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$user`:$pass"))
$base = 'http://127.0.0.1:8081'
$auth = @{Authorization = "Basic $pair" }
$job = $args[0]
if ([string]::IsNullOrWhiteSpace($job)) { $job = 'STEP/BwanaPlatform' }
$path = $job.Replace('/', '/job/')
$j = Invoke-RestMethod -Uri ($base + '/job/' + $path + '/api/json?tree=builds[number,result,building],lastBuild[number,result,building],inQueue') -Headers $auth -TimeoutSec 10
Write-Output ('inQueue=' + $j.inQueue)
foreach ($b in $j.builds) { Write-Output ('build num=' + $b.number + ' result=' + $b.result + ' building=' + $b.building) }
