$ErrorActionPreference = 'Stop'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $cs = Get-CimInstance -Namespace root/virtualization/v2 -ClassName Msvm_ComputerSystem -Filter ("ElementName='" + $vm + "'")
  if (-not $cs) { Write-Output ("{0}: NOT FOUND" -f $vm); continue }
  $kbd = Get-CimInstance -Namespace root/virtualization/v2 -Query ("SELECT * FROM Msvm_Keyboard WHERE SystemName='" + $cs.Name + "'")
  if (-not $kbd) { Write-Output ("{0}: NO KEYBOARD DEVICE" -f $vm); continue }
  try {
    foreach ($code in @(0x0D, 0x20)) {
      $r1 = Invoke-CimMethod -InputObject $kbd -MethodName PressKey -Arguments @{ keyCode = [uint16]$code }
      $r2 = Invoke-CimMethod -InputObject $kbd -MethodName ReleaseKey -Arguments @{ keyCode = [uint16]$code }
      Write-Output ("{0}: sent key 0x{1:X} press_rc={2} release_rc={3}" -f $vm, $code, $r1.ReturnValue, $r2.ReturnValue)
    }
  } catch { Write-Output ("{0}: KEY SEND FAILED: {1}" -f $vm, $_.Exception.Message) }
  $v = Get-VM -Name $vm
  Write-Output ("{0}: state={1} uptime={2}" -f $vm, $v.State, $v.Uptime)
}
