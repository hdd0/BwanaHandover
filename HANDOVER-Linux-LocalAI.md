# HANDOVER — Windows→Linux + Local AI Migration Guide
For Howard (hdd0), transfer to another Windows host running **Linux with Local AI**.

## STATUS AT TIME OF WRITE
PASS/PASS WITH WARNINGS: all tool installs verified; autologin attempt FAILED (registry denied); tools configured in opencode.json but NOT reloaded into OpenCode runtime; projects present under `C:\STEP` and `C:\Users\howar`; GitHub CLI authenticated as `hdd0`.

## 1. TOOLS INSTALLED (Windows host `NDIRANDEONE`)

| Tool | Location | Purpose | Linux equivalent |
|---|---|---|---|
| Git | `C:\Program Files\Git` | Repo management | `apt install git` |
| GitHub CLI (`gh`) | `C:\Program Files\GitHub CLI\gh.exe` | Pull/push/secrets | `npm i -g @anthropic-ai/cli gh` or apt |
| Docker Desktop | `C:\Program Files\Docker` | Containers | Docker engine (`apt install docker.io`) |
| PowerShell 5.1 | `pwsh` — present | Scripting | `sudo apt install powershell` |
| Terraform | winget install | IaC | `sudo apt install terraform` |
| kubectl | Docker\bin | K8s CLI | `sudo apt install kubectl` |
| Python 3.14 | `C:\Program Files\Python314` | Scripts/AI | `python3 --version` (verify ≥3.10) |
| Node.js | `C:\Program Files\nodejs` | MCP servers/npm | `node --version` (verify ≥20) |
| .NET SDK | `C:\Program Files\dotnet` | Builds | `dotnet --version` (verify ≥6.0) |
| NPM global packages (@modelcontextprotocol) | npm cache | MCP servers | `npm i -g @modelcontextprotocol/*` |

⚠️ On Linux, ensure **Terraform ≥0.60** and **Python ≥3.10** before sourcing IaC tasks.

## 2. CONFIG FILES (transfer these as-is)

```
C:\Users\howar\.config\opencode\opencode.json        # provider keys MCP list — MUST edit & reload
C:\Users\howar\.config\opencode\AGENTS.md           # Howard memory (legal, org, identity split)
C:\Users\howar\.config\opencode\PROJECT-LANDSCAPE.md # portfolio map of all projects
C:\Users\howar\AppData\Local\Temp\opencode\HANDOVER-Linux-LocalAI.md  # THIS FILE
C:\VirtualDisplayDriver\vdd_settings.xml             # VirtualDisplayDriver (optional)
C:\STEP\*                                            # ALL project repos + scripts
C:\Users\howar\BwanaTools\                           # mem scripts + supervisor tooling
```

### IMPORTANT opencode.json edits required on Linux
Add under `mcp`:
```json
"github": { "type": "local", "command": ["npx","-y","@github/modelcontextprotocol-server-github","mcp"] },
"terraform": { "type": "local", "command": ["npx","-y","@hashicorp/terraform-mcp-server","mcp"] }
```
Then reload OpenCode (`opencode` daemon restart) — existing MCP servers auto-connect.

API key note: `[REDACTED_OPENROUTER_KEY]...` currently bound to OpenRouter provider — works on Linux too. Redact when committing.

## 3. PROJECT DIRECTORY MAP

| Project | Path | Git origin | Status |
|---|---|---|---|
| BwanaAI | `C:\STEP\BwanaAI\BwanaAI` | ` hdd0/BwanaAI` (uncommitted) | Active |
| BwanaAD / bwana-infra | `C:\STEP\BwanaAD` | ` hdd0/bwana-infrastructure` | Jenkinsfile only (no Actions) |
| BWANA OKD Jenkins | `C:\STEP\BWANA-OKD-Jenkins` | — | Has jobs: VM/OKD/Compose |
| OKD spec | `C:\STEP\BWANA-OKD-FINAL-SPEC.md` | — | 20 sections binding docs |
| BwanaWiki | `C:\STEP\BwanaWiki` | ` hdd0/BwanaWiki` | Public source ingestion |
| BwanaPlatform | `C:\STEP\BwanaPlatform` | ` hdd0/BwanaPlatform` | Ahead of origin/main |
| HOWARD DAVID JAMBO | `C:\STEP\HOWARDDAVIDJAMBO` | ` hdd0/HOWARDDAVIDJAMBO` | Astro + store |
| bwana-infrastructure | `C:\STEP\bwana-infrastructure` | mirror | Dirty tree noted |
| openclaw | `C:\STEP\openclaw` | — | AI work (assistant) |
| lightpanda-gmail | `C:\STEP\lightpanda-gmail` | — | Gmail access (pending) |
| ngrok | `C:\STEP\ngrok` | — | CV tunnel (cv5050) |
| architect-platform | `C:\STEP\architect-platform` | — | control plane Next.js |
| step-ai-gateway | `C:\STEP\step-ai-gateway` | — | 3367 provider router |
| ai-jenkins-gateway | `C:\STEP\ai-jenkins-gateway` | — | Jenkins control |
| openship | `C:\STEP\openship` | mirror | App deployment |
| vaultwarden | `C:\STEP\vaultwarden` | — | Bitwarden compatible (8080 loopback) |
| OpenHVX | `C:\STEP\OpenHVX` | — | Hyper-V IaaS |
| hyperv-windows-vm | `C:\STEP\hyperv-windows-vm\src` | — | Hyper-V VM MCP server |
| jenkins-agent | `C:\STEP\jenkins-agent` | — | Windows Jenkins agent |
| jmeworkstation | `C:\STEP\BwanaAI\BwanaAI\dev` | — | display.ps1 screenshots |
| BwanaMail | `C:\STEP\BwanaMail` | ` hdd0/BwanaMail` | Renamed Sept 2026 (Exchange+Stalwart) |

NOTE: Some project dirs changed location between surveys. verify live on target before use.

## 4. VMS (Hyper-V on host) — for migration

All 9 VMs listed in profile inventory (verified Oct 8):

| VM | State | Switch | VLAN |
|---|---|---|---|
| BWANA-DC01 | Running | BWANA-AD-LAN | VLAN 150 |
| BWANA-DC02 | Running | BWANA-AD-LAN | VLAN 150 |
| BWANA-GOLDEN-SRC | Off | — | — |
| BWANA-NAS-01 | Running | OKD-LAN | untagged |
| BWANA-OKD-01..03, BOOTSTRAP | Off | OKD-LAN | untagged |

For Linux machine: PXE boot OKD nodes from network drive via OKD-LAN switch. Plan: stop OKD nodes during heavy load (host RAM oversubscribed: 88 GB vCPU sum vs 63.7 GB RAM).

## 5. AUTOSIGNIN — STILL BLOCKED

- Script: `C:\STEP\BwanaAD\scripts\enable-autologin.ps1`
- Account: `BWANA\Administrator`, password in `C:\STEP\unattend\golden\Autounattend.xml:47`
- Attempted: autologin setup (registry denied, needs Elevation)
- Fix: run elevated shell; then both DCs + mail server get same setup
- MD-compatible option: password-credential file read by script (less secure — use anyway for lab)

**Action:** elevated shell → `powershell.exe -NoProfile -File enable-autologin.ps1 -UserName Administrator -Password [REDACTED] -Domain BWANA -Count 0` → verify on both DCs.

## 6. LOCAL AI STACK (Windows verified)

Providers active in OpenCode workspace:

| Provider | Key/Config | Models available |
|---|---|---|
| OpenRouter | `[REDACTED_OPENROUTER_KEY]...` | 84 models incl free/openrouter/free |
| OpenCode (built-in) | managed | 83 enabled |
| atomic (Atomic Chat) | `atomic` baseURL 1337 | qwen3:0.6b |
| superpowers plugin | `git+https://github.com/obra/superpowers.git` | code workflows |
| opencode-lmstudio | `0.3.1` | LM Studio integration |

**Hot skills:** brainstorming, ab-testing, ad-creative, ads, ai-seo, analytics, seo-audit, schema, copywriting, cro, copy-editing, writing-skills, using-git-worktrees, snarktank/ralph, systematic-debugging, test-driven-development.

Rea: `morluto/rea` 93k stars — reverse engineer binaries/native/managed code.
Ralph: `snarktank/ralph` — autonomous loop running AI coding tools until PRD complete.

## 7. CHANGES MADE THIS SESSION (tooling)

- ✅ Terraform installed via winget (HashiCorp latest stable)
- ✅ GitHub MCP + Terraform MCP added to opencode.json
- ✅ MCP servers registry upgraded: `servers:` flat section
- REA research confirmed; RALPH confirmed; local AI stack confirmed

## 8. LINUX MIGRATION CHECKLIST

```bash
# System basics
sudo apt update && sudo apt upgrade -y
sudo apt install -y git gh docker.io terraform kubectl powershell python3 nodejs dotnet
sudo apt install -y terraform nginx && cd ~/bin

# Terraform v0.60+
terraform version  # check ≥0.60

# Node & npm
node --version  # check ≥20
npm i -g @modelcontextprotocol/server-github @modelcontextprotocol/server-terraform

# OpenCode CLI (install per opencode docs)
cd ~/.config/opencode/
# Edit mcp section: add github + terraform entries
# Reload services: pkill or restart opencode daemon

# Verify locally
opencode list-providers    # check providers loaded
opencode list-models      # check models available
```

## 9. KNOWN GOTCHAS

- ngrok must target **127.0.0.1:5050**, NOT localhost (IPv6 collision)
- `Set-VMFirmware -BootOrder` requires VM Off; read BootOrder via File entry
- Jenkins anonymous API returns 403; node offline (no agent service found)
- Vaultwarden on 8080 loopback only (not public yet)
- Stalwart is live+healthy — make this primary mail until Exchange available
- Certificates (.env files gitignored): redact credentials before commit
- KeePassXC database and Vaultwarden token in `~/.openship-vault` — preserve

## 10. VERIFY ON TARGET BEFORE CLAIMING DONE

After import, confirm in terminal:
```bash
git status                # project checkouts intact
terraform version         # ≥0.60
kubectl version           # kubeconfig OK
node --version            # ≥20
npm ls -g --depth=0       # MCP packages present
ls ~/.config/opencode/opencode.json  # config edited correctly
```
Then ask AI or I can verify one of your projects directly (list VMs / pull GitHub repo / build Terraform).
