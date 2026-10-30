# BwanaAI Linux Local AI Handover

Updated 2026-10-30 for the development PC at `/home/howarddavidjambo`.

## Current status

- BwanaAI gateway on `127.0.0.1:3366` and LiteLLM on `127.0.0.1:4000` are running and managed by user systemd services.
- OpenBao on `127.0.0.1:8200` is running. Provider credentials are held in OpenBao and the GNOME login keyring; no credential values belong in this repository.
- The LiteLLM database is a local Docker Compose service in `/home/howarddavidjambo/services/litellm`.
- The LiteLLM deployment exposed to BwanaAI is `openrouter/free`; the BwanaAI LiteLLM virtual key is restricted to that model.
- A live smoke request through BwanaAI `3366` to LiteLLM/OpenRouter returned HTTP 200 with provider `openrouter` and model `openrouter/free`.
- The OpenRouter monthly remaining quota is not available from this local setup, so BwanaAI must display it as unknown rather than infer a number. The selected route is the free model router.

## Local endpoints

| Service | Address | Purpose |
|---|---|---|
| BwanaAI gateway | `http://127.0.0.1:3366` | Local entry point for AI clients and BwanaAI chat |
| LiteLLM Admin UI | `http://127.0.0.1:4000/ui/` | Model deployment and virtual key administration |
| LiteLLM OpenAI-compatible API | `http://127.0.0.1:4000/v1` | Internal upstream for the 3366 gateway |
| OpenBao API | `http://127.0.0.1:8200` | Local secret storage; loopback only |

Chat aliases are `/BwanaAI`, `/bwanai`, `/bwana-ai`, and `/chat`. The LiteLLM login URL is `http://127.0.0.1:4000/ui/login/`. Opera uses a dedicated profile at `~/.local/share/litellm-admin-opera-profile`; its saved session is local to this PC.

## Startup and health checks

User services are enabled for the desktop user session:

```bash
systemctl --user status openbao.service litellm.service bwanai-hub.service bwanai-gateway.service
curl -fsS http://127.0.0.1:4000/health/readiness
curl -fsS http://127.0.0.1:3366/health
```

LiteLLM Compose files and its private `.env` are under `/home/howarddavidjambo/services/litellm`. Keep `.env`, Bao data, browser profile, and local runtime state out of Git. Do not copy secrets into shell history, handover docs, screenshots, or issues.

OpenBao bootstrap helper: `/step/repos/BwanaAI/gateway-3366/openbao-secrets.py`. It uses the unlocked GNOME login keyring to bootstrap/unseal OpenBao at desktop login. If the keyring is locked or unavailable, unlock the desktop keyring and inspect the user service logs:

```bash
journalctl --user -u openbao.service -u bwanai-hub.service -u litellm.service -n 100 --no-pager
```

## Routing and usage

Configure AI clients to use `http://127.0.0.1:3366/v1` where they support an OpenAI-compatible base URL. The BwanaAI chat page calls the local gateway on port 3366, which applies routing policy and sends the approved LiteLLM request to port 4000. Do not configure clients with a direct OpenRouter key or direct provider endpoint if they are meant to follow the local gateway policy.

The BwanaAI chat page tracks local request/token totals. These are usage observations, not a provider billing ledger. The OpenRouter free router can choose among free models, so exact model availability and provider limits can change. Verify provider quota in the provider account when it is exposed; show `unknown` when it is not.

## Relevant repositories and configuration

- Active BwanaAI source: `/step/repos/BwanaAI`
- BwanaAI clone: `/home/howarddavidjambo/projects/BwanaAI`
- This handover repository: `/step/repos/BwanaHandover`
- LiteLLM Compose project: `/home/howarddavidjambo/services/litellm`
- OpenBao config: `~/.config/openbao/openbao.hcl`
- User services: `~/.config/systemd/user/`
- OpenCode client config: `~/.config/opencode/opencode.json`

The BwanaAI repository may contain unrelated local modifications. Review `git status` before staging or committing there; do not stage broad changes as part of this handover.

## Documentation references

- LiteLLM Docker quickstart: <https://docs.litellm.ai/docs/proxy/docker_quick_start>
- OpenBao installation documentation: <https://openbao.org/docs/install/>
- OpenRouter free model router: <https://openrouter.ai/openrouter/free>
