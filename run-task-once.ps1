$ErrorActionPreference = 'Stop'
$before = (Get-Item 'C:\STEP\_github-sync\logs\sync-20261017.jsonl' -ErrorAction SilentlyContinue).LastWriteTime

Start-ScheduledTask -TaskName 'Bwana-GitHub-Portfolio-Sync'

$deadline = (Get-Date).AddMinutes(10)
do {
    Start-Sleep -Seconds 5
    $state = (Get-ScheduledTask -TaskName 'Bwana-GitHub-Portfolio-Sync').State
} while ($state -eq 'Running' -and (Get-Date) -lt $deadline)

$info = Get-ScheduledTaskInfo -TaskName 'Bwana-GitHub-Portfolio-Sync'
$after = (Get-Item 'C:\STEP\_github-sync\logs\sync-20261017.jsonl' -ErrorAction SilentlyContinue).LastWriteTime

Write-Output "State:              $state"
Write-Output "LastRunTime:        $($info.LastRunTime)"
Write-Output "LastTaskResult:     $($info.LastTaskResult) (0x$('{0:X}' -f $info.LastTaskResult))"
Write-Output "Log before:         $before"
Write-Output "Log after:          $after"
Write-Output "Log rewritten:      $($before -ne $after)"
Write-Output ''
Write-Output '=== last 3 log lines ==='
Get-Content 'C:\STEP\_github-sync\logs\sync-20261017.jsonl' -Tail 3 -ErrorAction SilentlyContinue