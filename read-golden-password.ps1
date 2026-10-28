$log = 'C:\Users\howar\AppData\Local\Temp\opencode\read-golden-password.log'
Start-Transcript -Path $log -Force | Out-Null

$vhdPath = 'C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx'
Mount-DiskImage -ImagePath $vhdPath -Access ReadWrite | Out-Null
$disk = Get-DiskImage -ImagePath $vhdPath | Get-Disk
Set-Disk -Number $disk.Number -IsOffline $false
$winPart = $disk | Get-Partition | Where-Object { $_.Type -eq 'Basic' -or $_.Type -eq 'Primary' } | Select-Object -First 1
$winPart | Set-Partition -NewDriveLetter W | Out-Null

"Windows drive: W:\"
"Files in W:\Windows\Panther\Unattend:"
Get-ChildItem 'W:\Windows\Panther\Unattend' -ErrorAction SilentlyContinue | Select-Object Name, Length | Format-Table -AutoSize

"Loading SOFTWARE hive"
$hivePath = 'W:\Windows\System32\config\SOFTWARE'
$loadedName = 'GOLDENSOFTWARE'
reg load "HKU\$loadedName" "$hivePath" | Out-String | Write-Host

$winlogonPath = "HKU:\$loadedName\Microsoft\Windows NT\CurrentVersion\Winlogon"
try {
    $props = Get-ItemProperty -Path $winlogonPath -Name AutoAdminLogon, DefaultUserName, DefaultDomainName, DefaultPassword -ErrorAction SilentlyContinue
    "AutoAdminLogon: $($props.AutoAdminLogon)"
    "DefaultUserName: $($props.DefaultUserName)"
    "DefaultDomainName: $($props.DefaultDomainName)"
    "DefaultPassword: $($props.DefaultPassword)"
} catch {
    "Error reading registry: $_"
}

[gc]::Collect()
Start-Sleep -Seconds 2
reg unload "HKU\$loadedName" | Out-String | Write-Host

# Remove drive letter
$winPart | Remove-PartitionAccessPath -AccessPath 'W:\' -ErrorAction SilentlyContinue
Dismount-DiskImage -ImagePath $vhdPath | Out-Null

Stop-Transcript | Out-Null
