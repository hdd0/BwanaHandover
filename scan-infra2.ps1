$ErrorActionPreference = 'Continue'
Write-Output "=== HOST ==="
$os = Get-CimInstance Win32_OperatingSystem
Write-Output "OS: $($os.Caption) $($os.Version)"
Write-Output "Host: $env:COMPUTERNAME"
$cs = Get-CimInstance Win32_ComputerSystem
Write-Output "CPU: $($cs.NumberOfLogicalProcessors) logical, RAM: $([math]::Round($cs.TotalPhysicalMemory/1GB,1)) GB"
Write-Output ""
Write-Output "=== DISKS ==="
Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, @{n='FreeGB';e={[math]::Round($_.FreeSpace/1GB,1)}}, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize
Write-Output ""
Write-Output "=== DOCKER CONTAINERS ==="
try { & docker ps --format "{{.Names}} | {{.Status}} | {{.Ports}}" 2>&1 } catch { Write-Output "docker unavailable" }
Write-Output ""
Write-Output "=== KEY SERVICES (mail/identity/infra) ==="
$svcNames = @('MSExchangeADDS','MSExchangeUM','MSExchangeIS','MSExchangeDiagnostics','Keycloak','docker','com.docker.service','W3SVC','MSDNS')
Get-Service -ErrorAction SilentlyContinue | Where-Object { $svcNames -contains $_.Name -or $_.Name -like '*Exchange*' } | Select-Object Name, Status, StartType | Format-Table -AutoSize
Write-Output ""
Write-Output "=== LISTENING PORTS (mail/web/infra) ==="
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
  Where-Object { $_.LocalPort -in 25,80,110,143,443,465,587,993,995,587,3000,3366,3367,3380,8080,8081,9090 } |
  Select-Object LocalAddress, LocalPort, @{n='Proc';e={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} |
  Sort-Object LocalPort -Unique | Format-Table -AutoSize
Write-Output ""
Write-Output "=== ROLES on host ==="
try { (Get-WindowsFeature | Where-Object { $_.InstallState -eq 'Installed' } | Select-Object -ExpandProperty Name) -join ', ' } catch { Write-Output "Get-WindowsFeature unavailable (Win11 client)" }
try { & dsquery /forest 2>&1 } catch {}
Write-Output "=== Host domain membership ==="
try { & whoami /upn 2>&1 } catch {}
& hostname