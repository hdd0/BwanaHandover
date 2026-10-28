$ErrorActionPreference = 'Continue'
Write-Output "=== STAGE 0: GOLDEN-SRC VERIFICATION ==="
$gs = Get-VM -Name 'BWANA-GOLDEN-SRC'
Write-Output "State      : $($gs.State)"
Write-Output "Heartbeat  : $($gs.Heartbeat)"
Write-Output "Uptime     : $($gs.Uptime)"
Write-Output "Generation : $($gs.Generation)"
Write-Output "CPU        : $($gs.ProcessorCount) vCPU"
Write-Output "Memory     : $([math]::Round($gs.MemoryAssigned/1GB,1)) GB assigned / $([math]::Round($gs.MemoryStartup/1GB,1)) GB startup"
Write-Output "IntegrSvc  : $($gs.IntegrationServicesState)"
Write-Output "IntegrSvcOK: $($gs.IntegrationServicesState.'Microsoft-Virtual-EMS'.'PrimaryStatusDescription')"
Write-Output "Adapters   : $((($gs.NetworkAdapters | ForEach-Object { $_.Name }) -join ', '))"
Write-Output "AdapterIP  : $(($gs.NetworkAdapters | ForEach-Object { $_.IPAddresses -join '+' }) -join ' | ')"
Write-Output "--- Disks ---"
$gs.HardDrives | ForEach-Object {
    $d = $_ | Get-VMHardDisk
    $sizeGB = [math]::Round((Get-VHD -Path $d.Path).Size/1GB,1)
    Write-Output ("{0} | {1} GB | {2}" -f $d.ControllerNumber, $sizeGB, (Split-Path $d.Path -Leaf))
}
Write-Output "--- Host free space (E: for ExchangeData) ---"
$e = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='E:'"
Write-Output "E: free $([math]::Round($e.FreeSpace/1GB,1)) GB of $([math]::Round($e.Size/1GB,1)) GB"
Write-Output "--- Boot order ---"
$fw = Get-VMFirmware -VMName 'BWANA-GOLDEN-SRC'
Write-Output ($fw.BootOrder | ForEach-Object { $_.Description }) -join ' > '
Write-Output "--- SecureBoot / TPM ---"
Write-Output "SecureBoot: $($fw.SecureBootTemplate -ne $null); TPM: $($gs.SecureBoot -ne $null -and $gs.TpmPresent)"
Write-Output ""
Write-Output "=== STALWART CONTAINER DETAIL ==="
& docker ps --filter "name=stalwart" --format "{{.Names}} | {{.Status}} | {{.Ports}}" 2>&1
Write-Output "--- Stalwart volume/config ---"
& docker inspect stalwart --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} ({{.Mode}}){{println}}{{end}}' 2>&1