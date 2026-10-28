$ErrorActionPreference = 'SilentlyContinue'
Write-Output "=== IDENTITY ==="
"Hostname      : $env:COMPUTERNAME"
"User          : $env:USERNAME"
$os = Get-CimInstance Win32_OperatingSystem
"OS Caption    : $($os.Caption)"
"OS Version    : $($os.Version)  Build $($os.BuildNumber)"
"PartOfDomain  : $((Get-CimInstance Win32_ComputerSystem).PartOfDomain)"
"DomainRole    : $((Get-CimInstance Win32_ComputerSystem).DomainRole)"
Write-Output ""
Write-Output "=== EXCHANGE SERVICES ==="
$ex = Get-Service | Where-Object { $_.Name -like 'MSExchange*' -or $_.DisplayName -like '*Exchange*' }
if ($ex) { $ex | Select-Object Name, Status, StartType | Format-Table -AutoSize | Out-String -Width 200 } else { Write-Output "NONE FOUND" }
Write-Output ""
Write-Output "=== EXCHANGE PROGRAM FILES ==="
foreach ($p in 'C:\Program Files\Microsoft\Exchange Server\V15','C:\Program Files\Microsoft\Exchange Server\V15\bin','C:\Program Files\Microsoft\Exchange Server\V15\Mailbox') {
  if (Test-Path $p) {
    $item = Get-Item $p
    $size = (Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    "EXISTS: $p  ({0:N2} MB, created {1})" -f ($size/1MB), $item.CreationTime
  } else { "ABSENT: $p" }
}
Write-Output ""
Write-Output "=== EXCHANGE REGISTRY ==="
foreach ($r in 'HKLM:\SOFTWARE\Microsoft\Exchange Server\V15\Setup','HKLM:\SOFTWARE\Microsoft\Exchange Server\V15\ServerConfiguration') {
  if (Test-Path $r) { Write-Output "EXISTS: $r"; Get-ItemProperty $r | Format-List | Out-String -Width 200 } else { Write-Output "ABSENT: $r" }
}
Write-Output ""
Write-Output "=== IIS SITES ==="
Import-Module WebAdministration -ErrorAction SilentlyContinue
if (Get-Command Get-Website -ErrorAction SilentlyContinue) { Get-Website | Select-Object Name, State, PhysicalPath | Format-Table -AutoSize | Out-String -Width 200 } else { Write-Output "WebAdministration module unavailable" }
Write-Output ""
Write-Output "=== .NET / FEATURES ==="
$netRel = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue).Release
".NET 4.x Release : $netRel"
$feats = Get-WindowsFeature -ErrorAction SilentlyContinue | Where-Object { $_.InstallState -eq 'Installed' }
"Windows Features Installed : $($feats.Count)"
$feats | Where-Object { $_.Name -match 'Web-|RSAT|NET-Framework|Server-Media|RPC' } | Select-Object -ExpandProperty Name | Sort-Object | Out-String -Width 200
Write-Output ""
Write-Output "=== PENDING REBOOT ==="
$pend = (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
"PendingReboot : $pend"
Write-Output ""
Write-Output "=== DISKS ==="
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter, FileSystemLabel, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}, @{n='FreeGB';e={[math]::Round($_.SizeRemaining/1GB,1)}} | Format-Table -AutoSize | Out-String -Width 200
Write-Output ""
Write-Output "=== NETWORK ==="
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.254*' } | Select-Object InterfaceAlias, IPAddress, PrefixLength | Format-Table -AutoSize | Out-String -Width 200
"WinRM: $((Get-Service WinRM).Status)"
Write-Output ""
Write-Output "=== EXCHANGE INSTALL LOGS (recent) ==="
$logRoot = 'C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\SetupLogs'
if (Test-Path $logRoot) { Get-ChildItem $logRoot -Recurse -Filter '*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 12 FullName, LastWriteTime, Length | Format-Table -AutoSize | Out-String -Width 250 }
else { Write-Output "No Exchange setup logs at $logRoot" }
Write-Output ""
Write-Output "=== EXCHANGE SETUP PROCESSES ==="
Get-Process | Where-Object { $_.ProcessName -match 'setup|msiexec|ecourier|wizard' } | Select-Object ProcessName, Id, StartTime | Format-Table -AutoSize | Out-String -Width 200
