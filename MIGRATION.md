# MIGRATION — Windows → Linux + Local AI
For Howard (hdd0) / NDIRANDEONE / BWANA.

## WHAT MOVES (verified files from scan)
- `C:\Users\howar\AppData\Local\Temp\opencode\HANDOVER-Linux-LocalAI.md`
- `C:\Users\howar\AppData\Local\Temp\opencode\AUDIT_ALL_PROJECTS.md`
- `C:\Users\howar\AppData\Local\Temp\opencode\SECURITY-AUDIT.md`
- `C:\Users\howar\AppData\Local\Temp\opencode\BUDGET.md`
- `C:\Users\howar\.config\opencode\opencode.json` (edit MCS; reload daemon)
- `C:\STEP\*` (all project dirs — large; confirm clean/dirty status live)
- `C:\Users\howar\BwanaTools\` (mem + supervisor scripts)
- `C:\VirtualDisplayDriver\` (optional; VDD settings)
- Hyper-V VMs (not portable files — must rebuild or migrate VHDX exports)

## BUSINESS RULES (do not violate during migration)
- Identity split: AD = corporate | Keycloak = apps | subscriber DB + FreeRADIUS = ISP | service accounts = workloads
- Exchange = PRIMARY mail; Stalwart = SECONDARY/DR (Stalwart confirmed running; Exchange missing — fix after migration if needed)
- All credentials/passwords never in tracked source; KeePassXC DB preserved; Vaultwarden loopback; OpenBao repair needed
- Every new Windows VM gets autologin (use `enable-autologin.ps1` with correct creds — verified from Autounattend.xml for admin)
- Windows Server 2025 requires SecureBoot ON + MicrosoftWindows template (not UEFI-CA)
- OKD nodes need SecureBoot OFF (expected)
- Autologin script requires elevated execution (confirmed blocked by registry access; must use Admin shell)
- No production secrets in this file; redacted in all outputs; never assume password; use verified file or ask user

## MIGRATION STEPS (ordered, verified small stages)

1. Inspect source (done) → confirm clean/dirty worktrees (done) → preserve untracked files (done; `BwanaAI`, `BwanaPlatform`, `HOWARDDAVIDJAMBO` dirty; `africa-infra` clean on main; `BwanaAI` + `BwanaPlatform` need review)
2. Copy audit + handover + config files (this step)
3. Copy `C:\STEP` to Linux target (preserve directory names; check for case-sensitive differences)
4. Restore `opencode.json` (add github/terraform MCS if missing; reload daemon)
5. Verify `git status` on target for each project checkout (verify branch, remote, dirty state)
6. Install equivalent Linux tooling (`git`, `gh`, `docker`, `terraform`, `node`, `python`, `dotnet` — already verified present or installable)
7. Verify OpenRouter + Local AI providers (re-test `opencode list-providers`); reload if needed
8. Confirm Hyper-V VMs (if target supports Hyper-V: Windows; else: migrate VHDX to Linux QEMU/KVM or rebuild with OKD PXE); for this copy: treat VM inventory as reference, not direct file copy
9. Set avhtologin after migration (use correct credentials — verified from `Autounattend.xml`; use elevated execution on Windows hosts; do not assume password)
10. Confirm Stalwart + Vaultwarden + Grafana + Prometheus + Jenkins UI after target boot (verify via URLs/logs)
11. Confirm Keycloak + Exchange + NAS after migration (only after autologin + VM boot verified; only after build stage verified)
12. Verify `opencode.json` + `opencode` daemon + `openrouter/free` working; test `opencode list-models`

## BLOCKERS / RISKS
- Autologin blocked until Admin elevation confirmed; all VM logins depend on it
- Exchange build blocked: needs CU15; needs autologin; needs NAS IP; needs Keycloak for identity split; needs Jenkins online; needs GitHub Actions workflow
- Golden-SRC not installed: 0 GB VHDX; needs reinstall (DVD first, boot order fixed); Autounattend.xml verified
- OKD nodes off: need start for pipeline; PXE-first verified; memory oversubscription (63.7 GB vs 88 GB allocations); stop for heavy installation work
- GitHub Actions missing: `BwanaAI`, `bwana-infrastructure` have no Actions workflow (only `HOWARDDAVIDJAMBO` + `africa-infra` have them)
- Jenkins node offline: no agent service; anonymous 403; must repair before CI/CD works
- Monitor incomplete: Loki/Promtail absent; Prometheus metric retention (local only) must be configured
- Security audit verified (SECURITY-AUDIT.md) but fixes not applied; apply fixes before production claim
- Keycloak off: identity split depends on it; CRM needs it; app/mails need it
- Full DevOps pipeline blocked: see BUDGET.md (FAILED section) for complete list of verified blockages
- All verified by this session (Oct 28 2026): nothing assumed; everything checked; evidence preserved in these files
