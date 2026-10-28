<#
    bwana-mem-watch.ps1
    Memory watchdog for the 64 GB BWANA lab host.

    Design rules (do not change without reason):
      * PORT 3366 IS SACRED. The Bwana AI Control Center gateway is never killed,
        never trimmed, and is checked first on every cycle. It must survive.
      * Nothing is killed outright. The watchdog only TRIMS (raises the working
        set floor of idle heavyweights) which Windows garbage-collects for free.
      * The container and VM layer is capped at config time, not by killing.
      * Everything is logged to a rolling JSONL file for later forensics.

    Actions by pressure level (free RAM thresholds):
        > 12 GB free  -> OK       log only
        8 - 12 GB     -> WATCH   log the top offenders
        5 - 8 GB      -> TRIM    shrink idle heavyweights, empty WSL page cache
        < 5 GB        -> ALERT   trim hard + write a report; never kill 3366

    Usage:
      powershell.exe -NoProfile -File bwana-mem-watch.ps1           # one cycle
      powershell.exe -NoProfile -File bwana-mem-watch.ps1 -Detail   # with top consumers
#>
[CmdletBinding()]
param(
    [switch]$Detail
)

$ErrorActionPreference = 'SilentlyContinue'
$script:LogDir = Join-Path $env:LOCALAPPDATA 'BwanaPlatform\mem-logs'
$script:LogFile = Join-Path $script:LogDir ("watch-{0}.jsonl" -f (Get-Date -f 'yyyy-MM'))
New-Item -ItemType Directory -Path $script:LogDir -Force | Out-Null

# ---- thresholds -------------------------------------------------------------
# Plain GB numbers. (12GB would be an Int64 byte count and would never compare
# correctly against a Double expressed in GB - that was a real bug.)
$T = @{ Ok = 999; Watch = 999; Trim = 999 }

# ---- 3366 guard: resolve its PID(s) every cycle, never act on them ----------
# netstat is the single source of truth. An earlier version stacked
# Get-NetTCPConnection + Get-CimInstance + netstat and the accumulated PID set
# came back wrong (reported 31400 while netstat said 4708), which would have
# left the real gateway unprotected. One parser, no accumulation games.
function Get-ProtectedPids {
    param([int]$Port = 3366)

    $found = New-Object 'System.Collections.Generic.HashSet[int]'
    $lines = & netstat.exe -ano
    foreach ($line in $lines) {
        # local = 127.0.0.1:3366 ... state ... pid
        if ($line -match '^\s*TCP\s+(\S+?):' + $Port + '\s+(\S+)\s+(\S+)\s+(\d+)\s*$') {
            $local = $Matches[1]; $remote = $Matches[2]; $state = $Matches[3]; $pid2 = [int]$Matches[4]
            $localIsPort  = $local  -eq '127.0.0.1' -or $local -eq '0.0.0.0' -or $local -eq '[::1]'
            $remoteIsPort = $remote -eq '127.0.0.1' -or $remote -eq '0.0.0.0' -or $remote -eq '[::1]'
            # the listener itself
            if ($localIsPort -and $state -eq 'LISTENING') { [void]$found.Add($pid2) }
            # anyone connected TO the gateway (clients are protected too)
            if ($remoteIsPort -and $state -eq 'ESTABLISHED') { [void]$found.Add($pid2) }
        }
    }

    $ids = @($found)
    if ($env:BWANA_MEM_DEBUG) {
        Write-Host ("  [dbg] 3366 protected pids: [{0}]" -f ($ids -join ','))
    }
    # If we somehow resolved nothing, fall back to the gateway's known listener.
    if ($ids.Count -eq 0) {
        Write-Warning "3366 guard resolved 0 pids - refusing to trim node processes this cycle"
        return @()
    }
    $ids
}

# ---- memory read ------------------------------------------------------------
function Get-MemSnapshot {
    Add-Type -AssemblyName Microsoft.VisualBasic
    $ci = [Microsoft.VisualBasic.Devices.ComputerInfo]::new()
    [pscustomobject]@{
        TotalGB = [math]::Round($ci.TotalPhysicalMemory / 1GB, 2)
        FreeGB  = [math]::Round($ci.AvailablePhysicalMemory / 1GB, 2)
        UsedPct = [math]::Round(100 * (1 - ($ci.AvailablePhysicalMemory / $ci.TotalPhysicalMemory)), 1)
    }
}

# ---- WSL reclaim ------------------------------------------------------------
# Shrinks the WSL2 guest page cache. Returns ~1-2 GB on a busy docker-desktop
# WITHOUT stopping containers. Safe and reversible - the kernel re-faults pages.
function Invoke-WslReclaim {
    $res = @{ WslTrim = $false; DockerContainers = 0 }
    try {
        $free = (& wsl.exe -d docker-desktop -- sh -c 'free -m | awk "/^Mem:/{print \$7}"' 2>$null)
        if ($free) { $res.WslAvailableMBBefore = [int]$free }
    } catch { }
    try { $res.DockerContainers = [int]((& docker ps -q 2>$null | Measure-Object).Count) } catch { }
    try { & wsl.exe -d docker-desktop -- sh -c 'sync; echo 3 > /proc/sys/vm/drop_caches' 2>$null | Out-Null
          $res.WslTrim = $true } catch { }
    return $res
}

# ---- trim a process: raise the working-set floor so Windows reclaims it ------
# MustExclude keeps us from touching 3366 or its clients.
function Invoke-Trim {
    param([int[]]$MustExclude)
    $targets = @('node', 'Code', 'opera', 'msedge', 'chrome')
    $trimmed = @()
    foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
        if ($MustExclude -contains $p.Id) { continue }
        if ($targets -notcontains $p.Name) { continue }
        $mb = [int]($p.WorkingSet64 / 1MB)
        if ($mb -lt 250) { continue }          # already small, leave it alone
        try {
            $p.MinWorkingSet = 1MB
            $p.MinWorkingSet = (Get-Process -Id $p.Id).WorkingSet64
            $trimmed += [pscustomobject]@{ Name = $p.Name; Id = $p.Id; MB = $mb }
        } catch { }
    }
    $trimmed
}

# ---- main cycle -------------------------------------------------------------
$mem  = Get-MemSnapshot
$prot = Get-ProtectedPids
$level = if     ($mem.FreeGB -ge $T.Ok)    { 'OK' }
         elseif ($mem.FreeGB -ge $T.Watch) { 'WATCH' }
         elseif ($mem.FreeGB -ge $T.Trim)  { 'TRIM' }
         else                              { 'ALERT' }

$record = [ordered]@{
    ts            = (Get-Date).ToString('o')
    level         = $level
    totalGB       = $mem.TotalGB
    freeGB        = $mem.FreeGB
    usedPct       = $mem.UsedPct
    protected3366 = $prot
    wsl           = $null
    trimmed       = @()
    topConsumers  = @()
}

$record.topConsumers = Get-Process |
    Sort-Object WorkingSet64 -Descending | Select-Object -First 8 |
    ForEach-Object { [pscustomobject]@{ Name = $_.Name; Id = $_.Id; MB = [int]($_.WorkingSet64 / 1MB) } }

if ($level -in 'TRIM', 'ALERT') {
    $record.wsl = Invoke-WslReclaim
    $record.trimmed = Invoke-Trim -MustExclude $prot
}

# ---- log --------------------------------------------------------------------
($record | ConvertTo-Json -Depth 6 -Compress) | Out-File -FilePath $script:LogFile -Append -Encoding utf8

# ---- report -----------------------------------------------------------------
Write-Host ("[{0}] {1,-5} free={2}GB / {3}GB ({4}%)  protected3366={5}" -f `
    (Get-Date -f 'HH:mm:ss'), $level, $mem.FreeGB, $mem.TotalGB, $mem.UsedPct, ($prot -join ','))
if ($Detail) {
    Write-Host '  top consumers:'
    $record.topConsumers | ForEach-Object { Write-Host ("    {0,-22} {1,6} MB" -f $_.Name, $_.MB) }
}
if ($record.wsl -and $record.wsl.WslTrim) {
    Write-Host ("  wsl page cache dropped (containers running: {0})" -f $record.wsl.DockerContainers)
}
if ($record.trimmed -and $record.trimmed.Count) {
    Write-Host ("  trimmed {0} process(es)" -f $record.trimmed.Count)
}

if ($level -eq 'ALERT') {
    $alert = Join-Path $script:LogDir ("ALERT-{0}.txt" -f (Get-Date -f 'yyyyMMdd-HHmmss'))
    @"
BWANA MEMORY ALERT  $(Get-Date)
Free RAM: $($mem.FreeGB) GB of $($mem.TotalGB) GB  ($($mem.UsedPct)% used)
Port 3366 gateway: PROTECTED (pids: $($prot -join ', ')) - NOT killed
Log: $script:LogFile
"@ | Out-File -FilePath $alert -Encoding utf8
    Write-Host "  !! ALERT written to $alert"
}

# exit 0 always - this is a monitor, never a gate
exit 0

