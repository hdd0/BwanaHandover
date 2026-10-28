$ErrorActionPreference = 'Continue'

Write-Output '=== host-side PSSessions (leak check) ==='
Get-PSSession | Select-Object Id, Name, State, ComputerName | Format-Table -AutoSize
Write-Output ('count=' + @(Get-PSSession).Count)

Write-Output ''
Write-Output '=== VM state / uptime / memory pressure ==='
foreach ($n in @('BWANA-DC01', 'BWANA-DC02')) {
    $v = Get-VM -Name $n
    $host = Get-VMHost
    [pscustomobject]@{
        Name        = $n
        State       = $v.State
        UptimeHours = [math]::Round($v.Uptime.TotalHours, 2)
        MemDemandMB = [math]::Round($v.MemoryDemand, 0)
        MemAssignMB = [math]::Round($v.MemoryAssigned / 1MB, 0)
        CPUUsage    = [math]::Round($v.CPUUsage, 1)
    } | Format-List
}

Write-Output ''
Write-Output '=== connectivity to DCs ==='
foreach ($ip in @('192.168.150.10', '192.168.150.11')) {
    $r = Test-NetConnection -ComputerName $ip -Port 5985 -WarningAction SilentlyContinue
    [pscustomobject]@{ IP = $ip; WinRM5985 = $r.TcpTestSucceeded; Ping = (Test-Connection $ip -Count 1 -Quiet) } | Format-Table -AutoSize
}