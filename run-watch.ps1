$ErrorActionPreference = 'Continue'
& 'C:\STEP\_github-sync\Watch-BwanaWorkstation.ps1' -Once *>&1 | ForEach-Object { "STREAM: $($_.GetType().Name): $_" }
