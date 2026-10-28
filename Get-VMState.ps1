$ErrorActionPreference = 'Continue'
$rows = foreach ($vm in Get-VM) {
    $fw = $null
    try { $fw = Get-VMFirmware -VMName $vm.Name } catch { }
    [PSCustomObject]@{
        Name       = $vm.Name
        State      = $vm.State
        Gen        = $vm.Generation
        SecureBoot = if ($fw) { $fw.SecureBoot } else { 'n/a' }
        Template   = if ($fw) { $fw.SecureBootTemplate } else { 'n/a' }
        vCPU       = $vm.ProcessorCount
        RAMAssignedGB = [math]::Round($vm.MemoryAssigned / 1GB, 1)
        RAMStartupGB = [math]::Round($vm.MemoryStartupBytes / 1GB, 1)
        Switch     = (Get-VMNetworkAdapter -VMName $vm.Name -ErrorAction SilentlyContinue).SwitchName
        BootOrder  = try { ($vm.BootOrder -join ' -> ') } catch { '' }
    }
}
$rows | Format-Table -AutoSize

Write-Host ''
Write-Host '--- Host capacity ---'
$os = Get-CimInstance Win32_OperatingSystem
Write-Host ("Host RAM total GB : {0}" -f [math]::Round($os.TotalVisibleMemorySize / 1MB, 1))
Write-Host ("Host RAM free  GB : {0}" -f [math]::Round($os.FreePhysicalMemory / 1MB, 1))
Write-Host ("Logical CPUs      : {0}" -f $env:NUMBER_OF_PROCESSORS)

Write-Host ''
Write-Host '--- VHDX / DVD inventory (relevant paths) ---'
Get-ChildItem -Path 'C:\Hyper-V' -Recurse -Include *.vhd,*.vhdx,*.iso -ErrorAction SilentlyContinue |
    Select-Object FullName, @{n='SizeGB';e={[math]::Round($_.Length / 1GB, 2)}}, LastWriteTime |
    Format-Table -AutoSize
