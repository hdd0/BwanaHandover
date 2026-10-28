$ErrorActionPreference = 'Stop'
$t = Get-ScheduledTask -TaskName 'Bwana-GitHub-Portfolio-Sync'
$info = Get-ScheduledTaskInfo -TaskName 'Bwana-GitHub-Portfolio-Sync'

[PSCustomObject]@{
    TaskName           = $t.TaskName
    State              = $t.State
    UserId             = $t.Principal.UserId
    LogonType          = $t.Principal.LogonType
    RunLevel           = $t.Principal.RunLevel
    MultipleInstances  = $t.Settings.MultipleInstances
    StartWhenAvailable = $t.Settings.StartWhenAvailable
    ExecutionTimeLimit = $t.Settings.ExecutionTimeLimit
    ActionExecute      = $t.Actions[0].Execute
    ActionArguments    = $t.Actions[0].Arguments
    TriggerCount       = @($t.Triggers).Count
    TriggerDetails     = (@($t.Triggers) | ForEach-Object {
        [PSCustomObject]@{
            Type       = $_.CimClass.CimClassName
            StartBound = $_.StartBoundary
            Enabled    = $_.Enabled
            UserId     = $_.UserId
            Interval   = $_.Repetition.Interval
        }
    })
    LastRunTime    = $info.LastRunTime
    LastTaskResult = $info.LastTaskResult
    NextRunTime    = $info.NextRunTime
} | ConvertTo-Json -Depth 5