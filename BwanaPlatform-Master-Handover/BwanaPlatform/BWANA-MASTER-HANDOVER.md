# BWANA PLATFORM MASTER HANDOVER

## Core purpose
Build sustainable technology and employment opportunities through reusable BwanaApps infrastructure. Every completed stage must finish GREEN, create a success story, publish observability data, version/push to Git, generate a report and move forward without getting stuck indefinitely on one defect.

## Foundation
- Hyper-V: shared compute foundation
- OPNsense: firewall/router/NAT/VPN/IDS/IPS enforcement
- DNS security/sinkhole + threat intelligence
- SNMP + NetFlow/IPFIX telemetry
- Prometheus metrics; Grafana dashboards; Loki logs; OpenTelemetry traces; Alertmanager alerts
- 3366: one-page control/observability plane
- ngrok AI Gateway: AI/model routing where configured; keep distinct from the 3366 application gateway
- MCP + agents: tools and automation
- Exchange primary mail; Stalwart fallback
- PHIL: supervised online watcher/recovery service
- Git: immediate versioning after each green stage

## Stage gate
1. Discover.
2. Build.
3. Smoke test.
4. QA using a different model from the build model.
5. GREEN => success story, Git commit/push, observability event, report, email summary, next stage.
6. RED => bounded debugging with alternate models, retest, QA again; if unresolved, create incident/ticket and preserve the completed work.

## Model policy
Default QA model: `nvidia/nemotron-3-ultra-550b-a55b`. NVIDIA currently lists a free endpoint and downloadable/self-hosted availability; verify quota/authentication at runtime. Do not assume unlimited free usage.

## Stages 1–8
1. Discovery and inventory of existing apps, services, ports, startup methods, Git, AI, Hyper-V and network.
2. Hyper-V standard: hosts, VMs, telemetry, startup/recovery, backups and resource policy.
3. OPNsense: segmented VLANs, firewall/NAT/VPN, API, IDS/IPS and safe AI proposal/approval workflow.
4. DNS sinkhole, SNMP, network flow and device telemetry.
5. Prometheus/Grafana/Loki/OpenTelemetry/Alertmanager and cross-correlation.
6. 3366 one-viewport SPA: grouped left menu, dashboard, reports/downloads, health and audit.
7. AI/MCP/ngrok AI Gateway/model routing; model switch between build and QA.
8. Exchange/Stalwart reporting, PHIL Windows service, boot persistence, automatic recovery/ticketing, GitOps and reusable BwanaApp standard.

## PHIL
PHIL monitors 3366, AI/build processes, commands, Hyper-V, OPNsense, MCP, agents, observability, Exchange, Stalwart and every BwanaApp. It may restart only allowlisted services/actions, create an incident, emit observability data, email, verify recovery and close the incident. PHIL must not execute arbitrary AI-generated commands.

## 5050 startup pattern
During Stage 1, inspect the existing 5050 application and determine whether it uses a Windows service, Scheduled Task, startup shortcut, Docker, NSSM or another mechanism. Reuse the proven startup pattern for all BwanaApps, without duplicate startup registrations.

## Reports
Each green stage generates a comprehensive report and a short Exchange email containing status, stage, checks, Git version and a link to the full report/3366 observability view. Failures generate incident mail with ticket ID and recovery status. Reports support PDF/CSV/JSON/XLSX where implemented.

## BwanaApp rule
Every BwanaApp must inherit the platform: central identity, secrets, firewall, DNS, observability, email, backup, 3366 registration, PHIL health monitoring, Git/versioning, startup persistence, `/health`, `/ready`, `/metrics` where appropriate, structured logs and incident/recovery integration.

## Safety
Do not automatically grant AI unrestricted Hyper-V Administrator, Domain Admin, root, Kubernetes cluster-admin, AWS AdministratorAccess or firewall administrator access. Use least privilege, approval gates, expiry for temporary blocks, configuration backups and rollback.
