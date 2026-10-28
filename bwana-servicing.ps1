$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$s = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
Invoke-Command -Session $s -ScriptBlock {
  'PROCS:'
  Get-Process -Name TiWorker, TrustedInstaller, dism, ServerManager -ErrorAction SilentlyContinue |
    Select-Object Name, Id, CPU, StartTime | Format-Table -AutoSize | Out-String | Write-Output
  'JOBS:'
  Get-Job | Select-Object Name, State | Format-Table -AutoSize | Out-String | Write-Output
  'PENDING-REBOOT:'
  $pr = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
          'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')
  foreach ($p in $pr) { $p + '=' + (Test-Path $p) }
  'CBS-TAIL:'
  try { Get-Content C:\Windows\Logs\CBS\CBS.log -Tail 5 -ErrorAction Stop } catch { 'CBS-UNREADABLE: ' + $_.Exception.Message }
} -ErrorAction Stop | Write-Output
Remove-PSSession $s
Write-Output 'DONE'
