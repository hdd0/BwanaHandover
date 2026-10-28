$vmName = 'BWANA-GOLDEN-SRC'
$answerDisk = 'C:\STEP\unattend\answer-GOLDEN.vhdx'
$backupPath = 'C:\Users\howar\AppData\Local\Temp\opencode\answer-GOLDEN-backup.vhdx'

# Backup answer disk
if (Test-Path $answerDisk) {
    "Backing up answer disk to $backupPath"
    Copy-Item -Path $answerDisk -Destination $backupPath -Force
    $backup = Get-Item $backupPath
    "Backup size: $([math]::Round($backup.Length/1MB,2)) MB"
} else {
    "Answer disk not found at $answerDisk"
    exit 1
}

# Stop OKD nodes to free RAM for Exchange build
$okdNodes = @('BWANA-OKD-01','BWANA-OKD-02','BWANA-OKD-03','BWANA-OKD-BOOTSTRAP')
foreach ($node in $okdNodes) {
    $vm = Get-VM -Name $node -ErrorAction SilentlyContinue
    if ($vm -and $vm.State -eq 'Running') {
        "Stopping $node (currently Running)"
        Stop-VM -Name $node -Save -ErrorAction Stop
    } else {
        "$node is $($vm.State)"
    }
}

# Start GOLDEN-SRC
$golden = Get-VM -Name $vmName
if ($golden.State -eq 'Off') {
    "Starting $vmName"
    Start-VM -Name $vmName
} else {
    "$vmName is $($golden.State)"
}

# Wait a few seconds and report state
Start-Sleep -Seconds 5
$golden = Get-VM -Name $vmName
"State: $($golden.State)"
"Uptime: $($golden.Uptime)"
"Status: $($golden.Status)"
"Heartbeat: $($golden.Heartbeat)"
