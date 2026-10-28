# Phase 1 elevated runner — launched via UAC (RunAs). Logs everything.
$ErrorActionPreference = 'Continue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir = 'C:\STEP\BwanaAD\logs'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$log = Join-Path $logDir ("phase1-elevated-$stamp.log")
Start-Transcript -Path $log -Force | Out-Null
Write-Output "=== BWANA Phase 1 elevated build $stamp ==="
Write-Output ("Admin check: " + ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator'))
Set-Location 'C:\STEP\BwanaAD'
Write-Output '--- STEP 1: bootstrap (preflight) ---'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\scripts\bootstrap.ps1'
Write-Output '--- STEP 2: deploy (switch + NAT + VM shells) ---'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\scripts\deploy.ps1' -IsoPath 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
Write-Output '--- DONE. Result VMs: ---'
Get-VM BWANA-DC01, BWANA-DC02 -ErrorAction SilentlyContinue | Format-Table Name, State, MemoryStartup -AutoSize
Stop-Transcript | Out-Null
Write-Output "Log saved: $log"
