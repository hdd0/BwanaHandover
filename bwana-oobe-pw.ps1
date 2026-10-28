$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
  [Runtime.InteropServices.Marshal]::SecureStringToBSTR(
    (((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString)))
$VK_SHIFT = 0x10; $VK_TAB = 0x09; $VK_ENTER = 0x0D
$special = @{ '!'=@(0x31,$true); '@'=@(0x32,$true); '#'=@(0x33,$true); '$'=@(0x34,$true);
  '%'=@(0x35,$true); '^'=@(0x36,$true); '&'=@(0x37,$true); '*'=@(0x38,$true);
  '?'=@(0xBF,$true); '-'=@(0xBD,$false); '_'=@(0xBD,$true); '='=@(0xBB,$false); '+'=@(0xBB,$true) }
function Send-Key($kbd, [uint16]$code) {
  $null = Invoke-CimMethod -InputObject $kbd -MethodName PressKey -Arguments @{ keyCode = $code }
  Start-Sleep -Milliseconds 60
  $null = Invoke-CimMethod -InputObject $kbd -MethodName ReleaseKey -Arguments @{ keyCode = $code }
  Start-Sleep -Milliseconds 80
}
function Send-Char($kbd, [char]$c) {
  $s = [string]$c
  if ($special.ContainsKey($s)) { $vk, $sh = $special[$s] }
  elseif ($s -cmatch '^[A-Z]$') { $vk = [uint16][char]$s; $sh = $true }
  elseif ($s -cmatch '^[a-z0-9]$') { $vk = [uint16][char]([string]$s).ToUpper(); $sh = $false }
  else { throw ("unsupported char in password") }
  if ($sh) { $null = Invoke-CimMethod -InputObject $kbd -MethodName PressKey -Arguments @{ keyCode = [uint16]$VK_SHIFT }; Start-Sleep -Milliseconds 60 }
  Send-Key $kbd $vk
  if ($sh) { $null = Invoke-CimMethod -InputObject $kbd -MethodName ReleaseKey -Arguments @{ keyCode = [uint16]$VK_SHIFT }; Start-Sleep -Milliseconds 60 }
}
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  $cs = Get-CimInstance -Namespace root/virtualization/v2 -ClassName Msvm_ComputerSystem -Filter ("ElementName='" + $vm + "'")
  $kbd = Get-CimInstance -Namespace root/virtualization/v2 -Query ("SELECT * FROM Msvm_Keyboard WHERE SystemName='" + $cs.Name + "'")
  $n = 0
  foreach ($c in $plain.ToCharArray()) { Send-Char $kbd $c; $n++ }
  Send-Key $kbd $VK_TAB
  foreach ($c in $plain.ToCharArray()) { Send-Char $kbd $c; $n++ }
  Send-Key $kbd $VK_ENTER
  Write-Output ($vm + ': sent password-entry sequence (' + $n + ' chars + Tab + Enter)')
}
Write-Output 'done; password value never logged'
