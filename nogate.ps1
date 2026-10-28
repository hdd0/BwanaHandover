# no-gate attempt: skip admin check, call Hyper-V directly
try {
  New-VMSwitch -Name 'BWANA-AD-LAN-TEST' -SwitchType Internal -ErrorAction Stop | Out-Null
  Write-Output 'CREATED (unexpected without admin)'
  Remove-VMSwitch -Name 'BWANA-AD-LAN-TEST' -Force -ErrorAction SilentlyContinue
} catch { Write-Output ('BLOCKED-BY-OS: ' + $_.Exception.Message) }
