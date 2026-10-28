<#
.SYNOPSIS Phase 1 elevated build - run as Administrator in PowerShell 5.1.
Run: powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\opencode\bwana-phase1-elevated.ps1"
#>
$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir = 'C:\STEP\BwanaAD\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ("phase1-elevated-" + $stamp + ".log")
Start-Transcript -Path $log -Force | Out-Null
Write-Output ("=== BWANA Phase 1 elevated build " + $stamp + " ===")
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
Write-Output ("Admin check: " + $isAdmin)
if (-not $isAdmin) { Write-Output 'NOT ELEVATED - right-click PowerShell -> Run as Administrator, then re-run.'; Stop-Transcript | Out-Null; exit 2 }
Write-Output '--- STEP 1: bootstrap (preflight) ---'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\STEP\BwanaAD\scripts\bootstrap.ps1'
if ($LASTEXITCODE -ne 0) { Write-Output 'bootstrap FAILED - fix before deploy.'; Stop-Transcript | Out-Null; exit 1 }
Write-Output '--- STEP 2: deploy (switch + NAT + VM shells) ---'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\STEP\BwanaAD\scripts\deploy.ps1' -IsoPath $iso
Write-Output '--- VERIFY ---'
Get-VMSwitch | Format-Table Name,SwitchType -AutoSize
Get-VM BWANA-DC01,BWANA-DC02 -ErrorAction SilentlyContinue | Format-Table Name,State,ProcessorCount -AutoSize
Get-NetNat -Name 'BWANA-AD-NAT' -ErrorAction SilentlyContinue | Format-Table Name,InternalIPInterfaceAddressPrefix -AutoSize
Write-Output ("Log: " + $log)
Write-Output 'NEXT: start each VM, install Windows Server, then apply dsc/DomainControllers/BwanaDC.ps1 (DC01=FirstDC, DC02=ReplicaDC).'
Stop-Transcript | Out-Null
