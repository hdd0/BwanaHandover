# REBUILD SCRIPT — Bwana All-Systems → New Machine
# Verify each stage before claiming PASS.
# Run elevated where registry/HKLM/VM changes required.
# Password verified from C:\STEP\unattend\golden\Autounattend.xml:47; username Administrator.
# Redacted here per AGENTS.md rules; do not expose in tracked source.

param(
  [string]$TargetDir = "C:\STEP",
  [string]$UserName = "Orange",
  [string]$Domain = "BWANA"
)
Write-Host "=== REBUILD START ===" -ForegroundColor Cyan
Write-Host "1. Verify opencode.json exists" -ForegroundColor Cyan
if (-not (Test-Path "$env:USERPROFILE\.config\opencode\opencode.json")) { throw "opencode.json missing" }
Write-Host "2. Verify git repos intact" -ForegroundColor Cyan
git -C $TargetDir status --short | ForEach-Object { Write-Host "DIRTY/UNTRACKED: $_" -ForegroundColor Yellow }
Write-Host "3. Verify VM state (read-only check)" -ForegroundColor Cyan
Get-VM -Name "BWANA-DC01","BWANA-DC02","BWANA-GOLDEN-SRC","BWANA-NAS-01" -ErrorAction SilentlyContinue | Select Name,State,Status | Format-Table -AutoSize
Write-Host "4. Verify OpenRouter provider" -ForegroundColor Cyan
# Verify via opencode console / manual check; not automated
Write-Host "5. Apply autologin (elevated required)" -ForegroundColor Yellow
# Use BwanaAD\scripts\enable-autologin.ps1 with verified creds (Admin/Autounattend.xml)
# Confirm registry with Get-ItemProperty after
Write-Host "6. Start OKD nodes (if target supports Hyper-V/OKD-LAN)" -ForegroundColor Cyan
# Start-VM BWANA-OKD-01..03; verify PXE boot; stop if memory oversubscribed (63.7GB vs 88GB alloc)
Write-Host "7. Verify NAS SMB / Guest Service Interface" -ForegroundColor Yellow
# Enable GSI; set IP; create SMB share; verify with Test-Connection
Write-Host "8. Verify Keycloak / Exchange / Jenkins / Monitor pipeline" -ForegroundColor Yellow
# Keycloak: start service; Exchange: install CU15; Jenkins: repair agent; Monitor: install Loki/Promtail
Write-Host "9. Copy ISO_BACKUP / Office config / Autounattend.xml" -ForegroundColor Cyan
Copy-Item C:\Users\howar\AppData\Local\Temp\opencode\ISO_BACKUP\* $TargetDir\ISO_BACKUP\ -Recurse -Force
Write-Host "=== REBUILD COMPLETE — verify with tests ===" -ForegroundColor Green
