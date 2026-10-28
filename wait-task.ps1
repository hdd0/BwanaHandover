$ErrorActionPreference = 'Continue'
$logPath = 'C:\STEP\_github-sync\logs\sync-20261017.jsonl'
$before = (Get-Item $logPath -ErrorAction SilentlyContinue).LastWriteTime

$deadline = (Get-Date).AddMinutes(25)
do {
    Start-Sleep -Seconds 15
    $state = (Get-ScheduledTask -TaskName 'Bwana-GitHub-Portfolio-Sync').State
    Write-Host ("{0:HH:mm:ss}  state={1}" -f (Get-Date), $state)
} while ($state -eq 'Running' -and (Get-Date) -lt $deadline)

$info = Get-ScheduledTaskInfo -TaskName 'Bwana-GitHub-Portfolio-Sync'
$after = (Get-Item $logPath -ErrorAction SilentlyContinue).LastWriteTime

Write-Output ''
Write-Output "Final state:       $state"
Write-Output "LastTaskResult:    $($info.LastTaskResult) (0x$('{0:X}' -f $info.LastTaskResult))"
Write-Output "Log before:        $before"
Write-Output "Log after:         $after"
Write-Output "Log rewritten:     $($before -ne $after)"
Write-Output ''
Write-Output '=== summary of newest log entry ==='
$last = Get-Content $logPath -Tail 1 | ConvertFrom-Json
$last.Results | Group-Object Status | Sort-Object Name | ForEach-Object { "  $($_.Name) = $($_.Count)" }
Write-Output "  Applied        = $($last.Applied)"
Write-Output "  Repositories   = $($last.RepositoryCount)"
Write-Output "  Checkouts      = $($last.CheckoutCount)"
Write-Output "  GeneratedAtUtc = $($last.GeneratedAtUtc)"
Write-Output "  Updated        = $(@($last.Results | Where-Object Status -eq 'Updated').Count)"