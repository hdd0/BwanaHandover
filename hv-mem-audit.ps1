$ErrorActionPreference = 'Continue'
$rows = foreach ($vm in Get-VM) {
    $m = $vm.MemoryAssigned
    $s = $vm.ProcessorCount
    [pscustomobject]@{
        Name   = $vm.Name
        State  = $vm.State
        RAM_GB = if ($m) { [math]::Round($m / 1GB, 1) } else { 0 }
        vCPU   = $s
        Dynamic= $vm.MemoryDynamic
        Start  = $vm.AutomaticStartAction
        Stop   = $vm.AutomaticStopAction
        Heartbeat = try { (Get-VMIntegrationService -VMName $vm.Name -Name 'Heartbeat').Enabled } catch { 'n/a' }
    }
}
$rows | Sort-Object State, Name | Format-Table -AutoSize
$run = ($rows | Where-Object { $_.State -eq 'Running' })
"RUNNING_VMS: $($run.Count)"
"RUNNING_RAM_GB: {0:N1}" -f (($run | Measure-Object RAM_GB -Sum).Sum)
