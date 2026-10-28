# cleanup leftover answer vhds
foreach ($v in @('C:\STEP\unattend\answer-DC01.vhdx','C:\STEP\unattend\answer-DC02.vhdx')) {
  Dismount-VHD -Path $v -ErrorAction SilentlyContinue
  Write-Output ("dismounted " + $v)
}
Get-VHD C:\STEP\unattend\answer-DC01.vhdx -ErrorAction SilentlyContinue | Format-List Attached | Out-String | Write-Output
Write-Output DONE-CLEAN
