$ErrorActionPreference = 'Continue'

Write-Output '=== TASK STATE NOW ==='
$t = Get-ScheduledTask -TaskName 'Bwana-GitHub-Portfolio-Sync'
$info = Get-ScheduledTaskInfo -TaskName 'Bwana-GitHub-Portfolio-Sync'
Write-Output "State:          $($t.State)"
Write-Output "LastRunTime:    $($info.LastRunTime)"
Write-Output "LastTaskResult: $($info.LastTaskResult) (0x$('{0:X}' -f $info.LastTaskResult))"
Write-Output "NextRunTime:    $($info.NextRunTime)"
Write-Output "NumberOfMissedRuns: $($info.NumberOfMissedRuns)"

Write-Output ''
Write-Output '=== CONSOLE SESSIONS ==='
quser 2>&1 | Out-String

Write-Output '=== POWERSHELL PROCESSES (sync candidates) ==='
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Select-Object ProcessId, ParentProcessId, CreationDate, CommandLine |
    Format-List | Out-String -Width 400

Write-Output '=== TASK SCHEDULER EVENTS (last 20 for this task) ==='
$log = 'Microsoft-Windows-TaskScheduler/Operational'
try {
    Get-WinEvent -FilterHashtable @{ LogName = $log; Id = 100, 101, 102, 103, 107, 110, 111, 129, 200, 201, 202, 203 } -MaxEvents 200 -ErrorAction Stop |
        Where-Object { $_.Message -like '*Bwana-GitHub-Portfolio-Sync*' } |
        Select-Object -First 20 TimeCreated, Id, LevelDisplayName, Message |
        Format-List | Out-String -Width 300
}
catch { Write-Output "Could not read $log : $($_.Exception.Message)" }

Write-Output '=== TASK SCHEDULER EVENTS (any task, last 15) ==='
try {
    Get-WinEvent -FilterHashtable @{ LogName = $log } -MaxEvents 15 -ErrorAction Stop |
        Select-Object TimeCreated, Id, LevelDisplayName, Message |
        Format-List | Out-String -Width 300
}
catch { Write-Output "Could not read $log : $($_.Exception.Message)" }