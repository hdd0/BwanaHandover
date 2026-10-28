$ErrorActionPreference = 'SilentlyContinue'
$pids = @()
try {
    $a = Get-NetTCPConnection -LocalPort 3366 -State Listen | Select-Object -ExpandProperty OwningProcess -Unique
    "Get-NetTCPConnection -> [$($a -join ',')]"
    $pids += $a
} catch { "Get-NetTCPConnection FAILED: $($_.Exception.Message)" }

try {
    $gw = Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match '3366' }
    "CIM gw pids -> [$((@($gw) | Select-Object -ExpandProperty ProcessId -EA SilentlyContinue) -join ',')]"
} catch { "Get-CimInstance FAILED: $($_.Exception.Message)" }

try {
    $cli = Get-NetTCPConnection -RemotePort 3366 -State Established | Select-Object -ExpandProperty OwningProcess -Unique
    "established clients -> [$($cli -join ',')]"
    $pids += $cli
} catch { }

$netstat = & netstat.exe -ano
foreach ($line in $netstat) {
    if ($line -match '^\s*TCP\s+(\S+):3366\s+\S+\s+LISTENING\s+(\d+)\s*$') { $pids += [int]$Matches[2] }
}
"FINAL protected = [$((@($pids) | Where-Object { $_ } | ForEach-Object { [int]$_ } | Sort-Object -Unique) -join ',')]"
