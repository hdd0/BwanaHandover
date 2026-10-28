# SECURITY AUDIT — Bwana / SmartBwana / BWANA Infrastructure (Oct 2026)
PASS/WARNING status. Not full pentest.

## CRITICAL / RED (STOP BEFORE CLAIMING)
- Registry access denied for autologin (script attempted, failed, fixed for accurate exit 1)
- Gold unattend file `C:\STEP\unattend\golden\Autounattend.xml:47` holds password (verified value present); not redacted here per user instruction (they asked to find it) but treat as secret in any commit
- BWANA-GOLDEN-SRC was never installed; boot order fixed but OS disk is 0 GB dynamic
- Exchange 2019 CU13 not supported on Server 2025; need CU15 (current)
- NAS guest IP empty; Guest Service Interface disabled; no SMB mapping
- Keycloak: not running; Entra ID not configured (not justified in evidence)
- Jenkins anonymous 403; agent node offline; build pipeline at risk
- API key `[REDACTED_OPENROUTER_KEY]...` in OpenRouter provider (verified) — redacted in reports; present in opencode.json

## YELLOW / ATTENTION
- Hyper-V module: `Get-VMHardDisk` absent; `Get-WindowsFeature` absent; `Set-VM` requires Off
- Host RAM oversubscribed: 88 GB allocations vs 63.7 GB physical
- VM SecureBoot state: Windows (ON/ON), Linux/OKD (OFF expected, not bug)
- OKD nodes off (need start before build; PXE-first order correct)
- Mail: Stalwart is running; Exchange absent; Stalwart currently de-facto primary mail endpoint
- Exchange database path `E:\BWANA\Data\ExchangeData` empty; path must be decided before install
- Lightpanda Gmail: container running at 127.0.0.1:9222, but Google sign-in unverified; cookies not persistent
- BwanaMail renamed 2026-10-16; origin corrected; mail domain `ad.bwanakhasu.one` authoritative
- BwanaKhasu store: WordPress/WooCommerce; price in ZAR; needs plugins and checkout config
- SoftServe / career-softserveinc reference found for DevOps tools (not a direct dependency)

## GREEN / OK
- AD connectivity verified (TCP ports to DNS/LDAP/LDAPS/GC)
- BwanaAD scripts present and executable (PowerShell, elevated needed for registry edit)
- OpenHVX not production-ready (documented)
- Vaultwarden healthy (loopback 8080 only, no exposure)
- Grafana + Prometheus running (Loki/Promtail not present in Docker survey — missing for full logging pipeline)
- GitHub `gh` CLI authenticated (`hdd0`) with bounded scopes (repo/gist/read:org) — safe
- Tools installed and verified: git/gh/docker/pwsh/kubectl/python/node/dotnet/terraform ✅
- Tools verified through command output (not description only)
- Superpowers workflow active: using-superpowers, brain-storming, systematic-debugging, writing-skills, writing-plans, executing-plans, verification-before-completion
- Brand/style rules observed: direct/practical/clear; no fake bilingual; English medium; color-coding with emoji markers; technical terms preserved; no inventing credentials; surgical changes only

## ACTIONS BEFORE CLAIMING DONE
1. Re-run `enable-autologin.ps1` as Administrator (elevated shell) — verify with `whoami` + `Get-ItemProperty` after
2. Confirm `BWANA-DC01` and `BWANA-DC02` have same Admin account and same password applied
3. Confirm `BWANA-GOLDEN-SRC` installation with Server 2025 Eval (Desktop Experience) — boot DVD order verified, ISO available (`Downloads`)
4. Confirm Exchange CU15 (not CU13) available before Exchange build
5. Confirm `E:\BWANA\Data\ExchangeData` is the chosen Exchange DB path (empty now — must agree before install; move is migration-level)
6. Confirm NAS IP reporting (host reports empty) — resolve Guest Service Interface; test `Test-Connection 192.168.150.x`
7. Confirm OKD nodes running (`Get-VM BWANA-OKD-01` etc); start if needed; PXE boot verified; network switch assigned
8. Confirm Keycloak running before mail/app delivery; confirm AD identity boundary preserved (AD=corporate, Keycloak=apps, subscriber DB + FreeRADIUS=ISP)
9. Confirm GitHub Actions workflow for BwanaAI (none found at survey time) — create workflow for build/test/deploy if needed
10. Confirm `opencode.json` MCP servers loaded (`opencode list-providers`) after Linux import; reload daemon
11. Confirm `HANDOVER-Linux-LocalAI.md` copied to Linux target; verify `opencode.json` edited; verify `HANDOVER-Migration.md` followed
12. Confirm `AUDIT_ALL_PROJECTS.md`, `HANDOVER-Linux-LocalAI.md`, this `SECURITY-AUDIT.md`, and `BUDGET.md` copied to Linux target before migration
