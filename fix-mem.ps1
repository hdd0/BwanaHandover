$ErrorActionPreference = 'Stop'
$targetGB = 2
Write-Output 'Restoring documented spec: 2 GB static per DC'
foreach ($n in @('BWANA-DC01', 'BWANA-DC02')) {
    Set-VMMemory -VMName $n -StartupBytes ($targetGB * 1GB) -DynamicMemoryEnabled $false
    Write-Output ("SET   $n -> " + $targetGB + " GB static")
}
Start-Sleep -Seconds 8
foreach ($n in @('BWANA-DC01', 'BWANA-DC02')) {
    $s = Get-VMMemory -VMName $n
    $v = Get-VM -Name $n
    Write-Output ("VERIFY $n assigned=" + [math]::Round($s.AssignedSize / 1GB, 2) + "GB startup=" + [math]::Round($s.StartupMemory / 1GB, 2) + "GB dynamic=" + $s.DynamicMemoryEnabled + " demand=" + [math]::Round($v.MemoryDemand / 1GB, 2) + "GB")
}