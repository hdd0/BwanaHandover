# BwanaAI Handover — 2026-10-31

## Summary
BwanaAI local-first AI gateway is fully wired and monitored.

## Key surfaces
- Gateway: http://127.0.0.1:3366 (single entry point)
- AI gateway: http://127.0.0.1:3367 (bwanai/auto)
- Monitor: http://127.0.0.1:3366/monitor (real-time, tab-closed & token-run-out safe)
- Chat: http://127.0.0.1:3366/BwanaAI (ChatGPT-style terminal UI)
- OpenCode web: http://127.0.0.1:4096
- OpenClaw: http://127.0.0.1:3366/openclaw

## MCP servers (7)
github, terraform, canva-dev, tinyfish, local-search, rea, ai-monitor (new, monitors the system)

## CLI
- bwana (chat), bwana --agent (agent), bwana --status/--monitor/--usage/--mcp/--tasks/--open
- MONITOR (single entry point command)

## Offline resilience
- Auto-switches to local models when hosted providers are unreachable.
- Tasks continue without internet.

## Secrets
- OpenBao (:8200) backs all provider tokens.

## NVIDIA
- Driver 595.99.02, CUDA 13.2, T1200 Laptop GPU. Ollama uses GPU.

## GitHub
- BwanaAI repo: https://github.com/hdd0/BwanaAI
- All changes pushed.