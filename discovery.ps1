$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole('Administrator')
Write-Output ("Admin=" + $admin)
Write-Output ("PS=" + $PSVersionTable.PSVersion.ToString())
Write-Output "---VMSwitch---"
Get-VMSwitch | Format-Table Name,SwitchType | Out-String | Write-Output
Write-Output "---VM---"
Get-VM | Format-Table Name,State | Out-String | Write-Output
Write-Output "---NAT---"
Get-NetNat | Format-Table Name,InternalIPInterfaceAddressPrefix | Out-String | Write-Output
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
Write-Output ("ISO_exists=" + (Test-Path $iso))
