Write-Output '--- UAC / admin ---'
Write-Output ("IsAdmin=" + ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator'))
Write-Output '--- Switch ---'
Get-VMSwitch -Name 'BWANA-AD-LAN' -ErrorAction SilentlyContinue | Format-Table Name, SwitchType -AutoSize
if (-not (Get-VMSwitch -Name 'BWANA-AD-LAN' -ErrorAction SilentlyContinue)) { Write-Output 'NO-SWITCH' }
Write-Output '--- NAT ---'
Get-NetNat -Name 'BWANA-AD-NAT' -ErrorAction SilentlyContinue | Format-Table Name, InternalIPInterfaceAddressPrefix -AutoSize
Write-Output '--- VMs ---'
Get-VM -Name 'BWANA-DC01' -ErrorAction SilentlyContinue | Format-Table Name, State -AutoSize
Get-VM -Name 'BWANA-DC02' -ErrorAction SilentlyContinue | Format-Table Name, State -AutoSize
Write-Output '--- VSCode task ---'
Get-ScheduledTask -TaskName 'VSCode-Elevated' -ErrorAction SilentlyContinue | Format-Table TaskName, State -AutoSize
