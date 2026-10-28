#requires -Version 7.4
[CmdletBinding()]
param([switch]$Resume)
$ErrorActionPreference='Stop'
$Root=$PSScriptRoot
$CfgPath=Join-Path $Root 'config/bwana-build.json'
$LogDir=Join-Path $Root '.bwana/logs'; $ReportDir=Join-Path $Root 'reports'; $SuccessDir=Join-Path $Root '.bwana/success-stories'
foreach($d in @($LogDir,$ReportDir,$SuccessDir)){New-Item -ItemType Directory -Force $d|Out-Null}
if(!(Test-Path $CfgPath)){throw "Missing $CfgPath. Configure it first."}
$C=Get-Content -Raw $CfgPath|ConvertFrom-Json -Depth 20
function Log($m,$level='INFO'){ $x="$(Get-Date -Format o) [$level] $m"; $x|Tee-Object -FilePath (Join-Path $LogDir 'orchestrator.log') -Append }
function Event3366($type,$severity,$msg,$data=@{}){ try{ $u="$($C.endpoints.gateway_3366.TrimEnd('/'))/api/observability/events"; Invoke-RestMethod $u -Method Post -ContentType 'application/json' -Body (@{event_type=$type;severity=$severity;message=$msg;timestamp=(Get-Date).ToUniversalTime().ToString('o');source='bwana-build-orchestrator';data=$data}|ConvertTo-Json -Depth 15)-TimeoutSec 8|Out-Null }catch{Log "3366 event failed: $($_.Exception.Message)" 'WARN'} }
function Run($cmd,$seconds,$label){ if([string]::IsNullOrWhiteSpace($cmd)){throw "$label command is not configured"}; Log "$label START"; $p=Start-Process pwsh -ArgumentList '-NoProfile','-Command',$cmd -WorkingDirectory $Root -PassThru -Wait -RedirectStandardOutput (Join-Path $LogDir "$label.out.log") -RedirectStandardError (Join-Path $LogDir "$label.err.log"); if($p.ExitCode -ne 0){throw "$label failed with exit $($p.ExitCode)"}; Log "$label PASS" 'GREEN' }
function GitGreen($stage){ git add -A; if((git status --porcelain)){git commit -m "feat(platform): complete stage $($stage.id) - $($stage.name)"|Out-Null}; if($C.git.push){git push $C.git.remote $C.git.branch|Out-Null} }
function Report($s,$status,$summary){$p=Join-Path $ReportDir "stage-$($s.id)-$(Get-Date -Format yyyyMMdd-HHmmss).md"; $body=@"
# Stage $($s.id) — $($s.name)

Status: **$status**
Time: $(Get-Date -Format o)

## Core purpose
$($C.business_purpose)

## Summary
$summary

## Observability
3366: $($C.endpoints.gateway_3366)
"@
$body | Set-Content $p -Encoding utf8; return $p}
foreach($s in $C.stages){
  Log "===== STAGE $($s.id): $($s.name) ====="; Event3366 'build.stage.started' 'INFO' $s.name @{stage=$s.id}
  try{
    $b=$C.commands.build -replace '{{STAGE_ID}}',$s.id -replace '{{STAGE_NAME}}',$s.name
    Run $b ([int]$C.build_timeout_seconds) "stage-$($s.id)-build"
    if($C.endpoints.gateway_3366){try{Invoke-WebRequest "$($C.endpoints.gateway_3366.TrimEnd('/'))/health" -TimeoutSec 8|Out-Null}catch{Log '3366 health check failed' 'WARN'}}
    $q=$C.commands.qa -replace '{{MODEL}}',$C.models.qa_model -replace '{{STAGE_ID}}',$s.id -replace '{{STAGE_NAME}}',$s.name
    try{Run $q ([int]$C.qa_timeout_seconds) "stage-$($s.id)-qa"}
    catch{
      $fixed=$false; $n=0
      foreach($m in $C.models.debug_models){if($n -ge [int]$C.max_debug_attempts){break};$n++;$d=$C.commands.debug -replace '{{MODEL}}',$m -replace '{{STAGE_ID}}',$s.id -replace '{{STAGE_NAME}}',$s.name; try{Run $d ([int]$C.debug_timeout_seconds) "stage-$($s.id)-debug-$n";Run $q ([int]$C.qa_timeout_seconds) "stage-$($s.id)-qa-retry-$n";$fixed=$true;break}catch{Log "debug/QA attempt $n failed: $($_.Exception.Message)" 'WARN'}}
      if(!$fixed){$r=Report $s 'RED' "QA failed after bounded debug attempts.";Event3366 'build.stage.failed' 'HIGH' "Stage $($s.id) failed" @{stage=$s.id;report=$r};break}
    }
    $r=Report $s 'GREEN' 'Build and independent QA passed.'; "# SUCCESS — Stage $($s.id)`n`n$($s.name)`n`nCompleted $(Get-Date -Format o).`n`n$($C.business_purpose)"|Set-Content (Join-Path $SuccessDir "stage-$($s.id)-$(Get-Date -Format yyyyMMdd-HHmmss).md") -Encoding utf8; GitGreen $s; Event3366 'build.stage.passed' 'INFO' "Stage $($s.id) passed" @{stage=$s.id;report=$r};Log "STAGE $($s.id) GREEN — proceeding" 'GREEN'
  }catch{ $r=Report $s 'RED' $_.Exception.Message; Event3366 'build.stage.failed' 'HIGH' $_.Exception.Message @{stage=$s.id;report=$r};Log $_.Exception.Message 'ERROR';break }
}
