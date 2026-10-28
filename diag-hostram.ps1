$ErrorActionPreference = 'Continue'
$os = Get-CimInstance Win32_OperatingSystem
Write-Output ('Host RAM total GB    = ' + [math]::Round($os.TotalVisibleMemorySize / 1MB, 2))
Write-Output ('Host RAM free  GB   = ' + [math]::Round($os.FreePhysicalMemory / 1MB, 2))
Write-Output ('Host commit limitGB = ' + [math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVirtualMemorySize / 1MB, 2))
Write-Output ('Host commit free GB = ' + [math]::Round((Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory / 1MB, 2))
Write-Output ''
Write-Output '=== VM memory config / state ==='
Get-VM | ForEach-Object {
    $m = Get-VMMemory -VMName $_.Name
    [pscustomobject]@{
        Name      = $_.Name
        State     = $_.State
        Assigned  = [math]::Round($m.AssignedSize / 1GB, 2)
        Startup   = [math]::Round($m.StartupMemory / 1GB, 2)
        Dynamic   = $m.DynamicMemoryEnabled
        Demand    = [math]::Round($_.MemoryDemand / 1GB, 2)
    }
} | Format-Table -AutoSize