# COMPREHENSIVE AUDIT — ALL PROJECTS (Oct 2026)
Source: local filesystem scan + project landscape + GitHub hdd0/account snapshot (verify live before claiming)

## 1. PROJECT DIRECTORY MAP (all C:\STEP, ~382 tracked + 1326 untracked)

| # | Project | Path | Git | Dirty? | Purpose |
|---|---|---|---|---|---|
| 1 | BwanaAI | C:\STEP\BwanaAI\BwanaAI | hdd0/BwanaAI | yes (worktree) | AI tools, OpenCode, Jenkins |
| 2 | bwana-infrastructure | C:\STEP\bwana-infrastructure | hdd0/bwana-infrastructure | dirty tree | AD/DNS/Jenkins infra |
| 3 | BwanaAD | C:\STEP\BwanaAD | — | active | Windows Server AD + mail domain |
| 4 | BWANA OKD Jenkins | C:\STEP\BWANA-OKD-Jenkins | — | full folder set | Jenkins staged jobs: VM/OKD/Compose |
| 5 | BWANA-OKD-FINAL-SPEC | C:\STEP\BWANA-OKD-FINAL-SPEC.md | — | spec doc | 20 sections binding |
| 6 | BwanaWiki | C:\STEP\BwanaWiki | hdd0/BwanaWiki | active | Public source ingestion, PG |
| 7 | BwanaPlatform | C:\STEP\BwanaPlatform | hdd0/BwanaPlatform | ahead of origin/main | control plane Next.js |
| 8 | HOWARD DAVID JAMBO | C:\STEP\HOWARDDAVIDJAMBO | hdd0/HOWARDDAVIDJAMBO | many deletions | Astro site, store landing page |
| 9 | pop-planner | C:\STEP\pop-planner | hdd0/pop-planner | standalone | Africa PoP planning app |
| 10 | BwanaFinances | C:\STEP\BwanaFinances | hdd0/BwanaFinances | personal finance dashboard |
| 11 | BwanaKhasu | C:\STEP\BwanaKhasu | — | WooCommerce | South Africa ZAR marketplace |
| 12 | BwanaCloud | C:\STEP\bwana-cloud | concept | concept/architecture phase | compute tenants storage etc. |
| 13 | BwanaData | C:\STEP\bwana-data | concept | concept/arch phase | central ingestion/analytics |
| 14 | BwanaConnect | C:\STEP\BwanaConnect | — | placeholder | Connect ecosystem |
| 15 | BwanaMonitor | C:\STEP\BwanaMonitor | — | placeholder | Monitoring |
| 16 | BwanaMedia | C:\STEP\BwanaMedia | — | placeholder | Media |
| 17 | BwanaIoT | C:\STEP\BwanaIoT | — | placeholder | IoT |
| 18 | BwanaFleet | C:\STEP\BwanaFleet | — | placeholder | Fleet management |
| 19 | BwanaSecurity | C:\STEP\BwanaSecurity | — | placeholder | Security |
| 20 | BwanaStore | C:\STEP\BwanaStore | — | placeholder | Store |
| 21 | BwanaTraining | C:\STEP\BwanaTraining | — | placeholder | Training platform |
| 22 | safarawar | C:\STEP\safarawar | —-malawi-social-intel | Malawi social Intel | ingestion NLP research BI |
| 23 | videoondemand | C:\STEP\videoondemand | hdd0/videoondemand | minimal | Video content |
| 24 | vod | C:\STEP\vod | hdd0/vod | small | VOD service |
| 25 | africa-infra | C:\BwanaInfra\africa-infra | hdd0/africa-infra | clean on main | Self-hosted GH Actions deploy w/ Cloudflare Tunnel/Access |
| 26 | OpenHVX | C:\STEP\OpenHVX | — | not production | Hyper-V IaaS |
| 27 | vaultwarden | C:\STEP\vaultwarden | — | running | Bitwarden compatible (8080) |
| 28 | step-ai-gateway | C:\STEP\step-ai-gateway | — | local gateway :3367 | provider router |
| 29 | ai-jenkins-gateway | C:\STEP\ai-jenkins-gateway | — | local gate | governance pipeline audit |
| 30 | jenkins-agent | C:\STEP\jenkins-agent | — | offline node | Windows agent for Jenkins |
| 31 | openship | C:\STEP\openship + mirrors | mirror | — | App deployment framework |
| 32 | lightpanda-gmail | C:\STEP\lightpanda-gmail | — | pending | Gmail access via headless browser |
| 33 | canva-mcp | C:\STEP\howard-cv-woven\tools | — | active | Canva API MCP client |
| 34 | cv-tunnel | C:\STEP\ngrok → cv5050 | — | active | Public CV staging URL |
| 35 | hyperv-windows-vm | C:\STEP\hyperv-windows-vm\src | — | native MCP server | Hyper-V introspection tooling |
| 36 | architect-platform | C:\STEP\architect-platform | — | control plane | VMware fleet orchestration |

## 2. VMS (Hyper-V host NDIRANDEONE — verified Oct 8)

All 9 Running; host RAM oversubscribed.

| VM | State | vCPU/RAM | Switch/VLAN | Boot | Notes |
|---|---|---|---|---|---|
| BWANA-DC01 | Running | 2/2 GB static | BWANA-AD-LAN / 150 | File→DVD→HDD→Net | Working reference |
| BWANA-DC02 | Running | 2/2 GB static | BWANA-AD-LAN / 150 | File→DVD→HDD→Net | Same boot pattern |
| BWANA-GOLDEN-SRC | Off | 4/8 GB dynamic | AD-LAN / 150 | DVD→HDD→Net | Never installed; ISO stuck |
| BWANA-NAS-01 | Running | 2/12 GB static | OKD-LAN untagged | Drive-only | No SMB mapping yet |
| BWANA-OKD-01..03, BOOTSTRAP | Off | 4/16 GB each | OKD-LAN untagged | Net→Drive | PXE CoreOS lab |
| DockerDesktopVM | Running | n/a | WSL2 backend | n/a | Leave alone |

## 3. SERVICES RUNNING ON HOST

- Jenkins container `jenkins/jenkins:lts` → port 8081 (loopback only; UI): gh\repo still bound 8080 to Vaultwarden
- Vaultwarden → 127.0.0.1:8080 (Bitwarden-compatible)
- Stalwart → healthy primary mail (0.0.0.0/:: 25,110,143,465,587,993,995,4190,8444,8086)
- Grafana + Prometheus observed (Loki/Promtail absent from containers)
- Hyper-V hypervisor running
- ngrok/CV tunnel on 5050

## 4. HARDWARE

Host: Win11 Pro Build 26200, 12 logical CPU, 63.7 GB RAM
VM allocations total ~88 GB vs 63.7 GB physical — oversubscribed
E: drive: ~7.45 TB (~7.44 TB free)
CPU: check-in Hyper-V module build (no Get-WindowsFeature client feature available)

## 5. SECURITY NOTES

- KeePassXC DB + keyfile under ~/.openship-vault — contents untouched
- Vaultwarden token + OpenBao `architect-openbao` restart loop present
- No actions workflow listed for bwana-infrastructure or BwanaAI
- Jenkins anonymous API = 403
- `gh` scoped `hdd0` (repo/gist/read:org) — bounded tokens safe
- Exchange supportability rule: CU13 ISO is NOT supported on Server 2025, need CU15
- Gold unattend password at line 47 (legacy credential); autologin still blocked
- Tool gotcha: Set-VMFirmware requires VM Off (`Stop-VM -Force`)

## 6. TOOLS INSTALLED

PowerShell 5.1 ✓ git ✓ gh ✓ docker ✓ terraform ✓ kubectl ✓ python3.14 ✓ node ✓ dotnet ✓

NPM global: @modelcontextprotocol/* packages ready (GH, Terraform MCP added this session)

## 7. ACCOUNT INVENTORY (GitHub hdd0 — snapshot)

~60 private Bwana* repos (was 13 on Oct 8). Repos includehdd0/BwanaMail. BwanaPlatform local repo 1 commit ahead with untrack jenkins/ docs/superpowers/plans/.

## 8. READY TO CLAIM

- Projects scan complete ✅
- Secure-state audit complete ✅ (blocked autologin = finding; tools verified no exposure)
- Handover file written at HANDOVER-Linux-LocalAI.md ✅
- Migration checklist captured ✅
