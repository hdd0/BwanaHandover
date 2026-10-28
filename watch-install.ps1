$ErrorActionPreference = 'Continue'
# READ-ONLY monitor. Changes nothing. Samples DC OS disk growth + VM state.
$targets = @(
  @{Name='BWANA-DC01'; Disk='C:\Hyper-V\AD\BWANA-DC01\BWANA-DC01.vhdx'},
  @{Name='BWANA-DC02'; Disk='C:\Hyper-V\AD\BWANA-DC02\BWANA-DC02.vhdx'}
)
$iterations = 4
for ($i=1; $i -le $iterations; $i++) {
    Write-Host ("=== sample {0}  {1} ===" -f $i, (Get-Date -Format 'HH:mm:ss'))
    foreach ($t in $targets) {
        $vmState = (Get-VM -Name $t.Name -ErrorAction SilentlyContinue).State
        $size = if (Test-Path $t.Disk) { [math]::Round((Get-Item $t.Disk).Length/1MB,1) } else { 'n/a' }
        Write-Host ("  {0,-12} state={1,-8} osdisk={2} MB" -f $t.Name, $vmState, $size)
    }
    if ($i -lt $iterations) { Start-Sleep -Seconds 25 }
}
Write-Host "watch complete (no changes made)"
