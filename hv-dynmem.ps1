$ErrorActionPreference = 'Continue'

# Auto-scaling memory policy (this host uses the older -Bytes parameter set).
# DCs stay STATIC on purpose: Hyper-V dynamic memory is not safe for domain
# controllers - hot-add lands after boot and a DC needs stable memory for
# FSMO/DB consistency.
# Lab workloads get real dynamic memory so they scale DOWN when idle.

$gb = 1GB
$policy = @(
    @{ Name = 'BWANA-GOLDEN-SRC';    Startup = 2;  Min = 2;  Max = 8  }
    @{ Name = 'BWANA-NAS-01';        Startup = 4;  Min = 4;  Max = 12 }
    @{ Name = 'BWANA-OKD-01';        Startup = 4;  Min = 4;  Max = 16 }
    @{ Name = 'BWANA-OKD-02';        Startup = 4;  Min = 4;  Max = 16 }
    @{ Name = 'BWANA-OKD-03';        Startup = 4;  Min = 4;  Max = 16 }
    @{ Name = 'BWANA-OKD-BOOTSTRAP'; Startup = 4;  Min = 4;  Max = 16 }
)

foreach ($p in $policy) {
    $vm = Get-VM -Name $p.Name -ErrorAction SilentlyContinue
    if (-not $vm)            { "SKIP  $($p.Name) - not found";            continue }
    if ($vm.State -ne 'Off') { "SKIP  $($p.Name) - $($vm.State)";           continue }
    try {
        Set-VMMemory -VMName $p.Name `
            -DynamicMemoryEnabled $true `
            -StartupBytes ($p.Startup * $gb) `
            -MinimumBytes  ($p.Min * $gb) `
            -MaximumBytes  ($p.Max * $gb) `
            -Buffer 20 `
            -ErrorAction Stop
        "OK    $($p.Name) -> dynamic $($p.Min)GB-$($p.Max)GB, startup $($p.Startup)GB, buffer 20%"
    } catch {
        "FAIL  $($p.Name) : $($_.Exception.Message)"
    }
}

"--- applied ---"
foreach ($n in @('BWANA-GOLDEN-SRC','BWANA-NAS-01','BWANA-OKD-01','BWANA-OKD-02','BWANA-OKD-03','BWANA-OKD-BOOTSTRAP')) {
    $vm = Get-VM -Name $n -ErrorAction SilentlyContinue
    if (-not $vm) { continue }
    $m = Get-VMMemory -VMName $n
    "{0,-22} {1,-6} dyn={2,-6} start={3,-6} min={4,-6} max={5}" -f $vm.Name, $vm.State, $m.DynamicMemoryEnabled, $m.StartupMemory, $m.MinimumMemory, $m.MaximumMemory
}

"--- DCs (static, intentional) ---"
foreach ($n in 'BWANA-DC01','BWANA-DC02') {
    $m = Get-VMMemory -VMName $n -ErrorAction SilentlyContinue
    if ($m) { "{0,-12} {1,-8} dyn={2,-6} assigned={3}GB" -f $n, (Get-VM $n).State, $m.DynamicMemoryEnabled, [math]::Round($m.MemoryAssigned/1GB,1) }
}
