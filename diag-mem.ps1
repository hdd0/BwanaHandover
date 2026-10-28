$ErrorActionPreference = 'Stop'
foreach ($n in @('BWANA-DC01', 'BWANA-DC02')) {
    $v = Get-VM -Name $n
    $s = Get-VMMemory -VMName $n
    Write-Output ("=== $n ===")
    Write-Output ("  assigned      : " + [math]::Round($s.AssignedSize / 1GB, 2) + " GB")
    Write-Output ("  startup       : " + [math]::Round($s.StartupMemory / 1GB, 2) + " GB")
    Write-Output ("  minimum       : " + [math]::Round($s.Minimum / 1MB, 0) + " MB")
    Write-Output ("  maximum       : " + [math]::Round($s.Maximum / 1GB, 2) + " GB")
    Write-Output ("  dynamic       : " + $s.DynamicMemoryEnabled)
    Write-Output ("  demand (bytes): " + $v.MemoryDemand)
    Write-Output ("  demand (GB)   : " + [math]::Round($v.MemoryDemand / 1GB, 2))
}