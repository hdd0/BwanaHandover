$ErrorActionPreference = 'Stop'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $fw = Get-VMFirmware -VMName $vm
  $v = Get-VM -Name $vm
  $hd = Get-VMHardDiskDrive -VMName $vm | Where-Object { $_.Path -notlike '*answer-*.vhdx' } | Select-Object -First 1
  $sz = (Get-Item $hd.Path).Length
  Write-Output ($vm + ': template=' + $fw.SecureBootTemplate + ' secureboot=' + $fw.SecureBoot + ' uptime=' + $v.Uptime + ' osdisk=' + $sz)
}
