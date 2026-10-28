$ErrorActionPreference = 'Continue'
Write-Output "=== HYPER-V VMS ==="
Get-VM | Select-Object Name, State, Generation | Format-Table -AutoSize
Write-Output "=== EXCHANGE PRESENCE (host) ==="
$exch = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup" -ErrorAction SilentlyContinue
if ($exch) { $exch | Select-Object MsiProductMajor, MsiProductMinor, MsiBuildMajor | Format-List } else { Write-Output "No Exchange install on host" }
Write-Output "=== AD DS ROLE (host) ==="
$adds = Get-WindowsFeature -Name AD-Domain-Services -ErrorAction SilentlyContinue
if ($adds) { Write-Output "AD-Domain-Services: $($adds.InstallState)" } else { Write-Output "Get-WindowsFeature unavailable (client OS?)" }
Write-Output "=== GH AUTH ==="
& gh auth status 2>&1
Write-Output "=== GIT REMOTE (BwanaPlatform) ==="
Set-Location C:\Users\howar\RiderProjects\BwanaPlatform
git remote -v
git status -sb
