$ErrorActionPreference = 'Stop'

# Create a scheduled task that keeps WSL Ubuntu alive and OpenShip running
# Runs at boot, runs as SYSTEM (highest), restarts on failure

$taskName = 'OpenShip-WSL-Keeper'
$description = 'Keeps WSL2 Ubuntu VM alive and OpenShip Docker Compose stack running persistently'

# The action: start Ubuntu, bring up compose, then hold the session open
# Using wsl.exe -d Ubuntu -e sh -c '...' with a long-running command
$command = 'wsl.exe'
$arguments = '-d Ubuntu -e sh -c "cd /root/.openship/compose && docker compose up -d --remove-orphans && exec sleep infinity"'

# Create the task
$action = New-ScheduledTaskAction -Execute $command -Argument $arguments
$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:02:00
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 2) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -RunOnlyIfNetworkAvailable `
    -WakeToRun

$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

try {
    # Remove existing if present
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    
    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description $description `
        -Force `
        -ErrorAction Stop
    
    Write-Host "✔ Registered scheduled task: $taskName"
    
    # Start it now
    Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Write-Host "✔ Started task"
    
} catch {
    Write-Error "Failed to register task: $($_.Exception.Message)"
    exit 1
}

# Verify
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Host ""
    Write-Host "Task details:"
    $task | Select-Object TaskName, State, @{n='NextRun';e={$task.Triggers[0]}}, @{n='RunLevel';e={$task.Principal.RunLevel}} | Format-List
}