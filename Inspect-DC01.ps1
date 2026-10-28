$ErrorActionPreference = 'Continue'
Write-Host '=== DC01 exact settings ==='
$vm = Get-VM -Name 'BWANA-DC01'
$fw = Get-VMFirmware -VMName 'BWANA-DC01'
$os = Get-VMCimInstance -VMName 'BWANA-DC01'
[PSCustomObject]@{
    Generation        = $vm.Generation
    SecureBoot        = $fw.SecureBoot
    SecureBootTemplate= $fw.SecureBootTemplate
    BootOrder         = ($fw.BootOrder -join ' -> ')
    vCPU              = $vm.ProcessorCount
    MemoryStartupGB   = [math]::Round($vm.MemoryStartupBytes/1GB,2)
    MemoryMinGB       = [math]::Round($vm.MemoryMinimum/1GB,2)
    MemoryMaxGB       = [math]::Round($vm.MemoryMaximum/1GB,2)
    DynamicMemory     = $vm.DynamicMemoryEnabled
    SwitchName        = (Get-VMNetworkAdapter -VMName 'BWANA-DC01').SwitchName
    SwitchType        = (Get-VMNetworkAdapter -VMName 'BWANA-DC01').SwitchType
    MacAddress        = 'auto'
    VlanId            = (Get-VMNetworkAdapterVlan -VMName 'BWANA-DC01' -ErrorAction SilentlyContinue).AccessVlanId
    AutoStart         = $vm.AutomaticStartAction
    AutoStop          = $vm.AutomaticStopAction
    GuestService      = $vm.GuestServiceEnabled
    Checkpoints       = $vm.CheckpointType
} | Format-List

Write-Host '=== DC01 drives ==='
$vm.Drives | ForEach-Object {
    [PSCustomObject]@{
        Path = $_.Path
        Type = $_.ControllerType
        Media = $_.Media
        SizeGB = if ($_.Size) { [math]::Round($_.Size/1GB,2) } else { '' }
    }
} | Format-Table -AutoSize

Write-Host '=== DC01 integration services ==='
Get-VMIntegrationService -VMName 'BWANA-DC01' | Select-Object Name, Enabled | Format-Table -AutoSize

Write-Host '=== Guest OS inside DC01 ==='
if ($os) {
    [PSCustomObject]@{
        Caption   = $os.Caption
        Version   = $os.Version
        Build     = $os.BuildNumber
        Hostname  = $os.CSName
        IP        = (@($os.NetworkAdapters | ForEach-Object { $_.IPAddresses } | Where-Object { $_ -match '^\d+\.' }) -join ', ')
    } | Format-List
} else { Write-Host 'No guest integration data.' }
