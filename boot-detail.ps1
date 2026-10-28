foreach ($n in @('BWANA-DC01','BWANA-GOLDEN-SRC')) {
  Write-Output "===== $n BootOrder detail ====="
  $b = (Get-VMFirmware -VMName $n).BootOrder
  foreach ($e in $b) {
    $e | Select-Object * | Format-List | Out-String | Write-Output
  }
}
