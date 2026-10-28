# Bwana Platform Build Starter

1. Review `BWANA-MASTER-HANDOVER.md`.
2. Configure `config/bwana-build.json` with your actual build/QA/debug agent commands and endpoints.
3. Confirm the Git remote and branch.
4. Start with discovery; do not enable destructive automation before approval and rollback are tested.

Run from PowerShell 7.4+:

```powershell
pwsh .\Invoke-BwanaPlatformBuild.ps1
```
