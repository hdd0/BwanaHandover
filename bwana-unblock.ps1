$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$s1 = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
Invoke-Command -Session $s1 -ScriptBlock {
  Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
  Stop-Service -Name BITS -Force -ErrorAction SilentlyContinue
  'WU-STOPPED'
  Start-Sleep -Seconds 45
  $ti = Get-Process -Name TiWorker -ErrorAction SilentlyContinue
  if ($ti) { 'TIWORKER-STILL-RUNNING cpu=' + $ti.CPU } else { 'TIWORKER-GONE' }
} -ErrorAction Stop | Write-Output
Remove-PSSession $s1
$s2 = New-PSSession -VMName 'BWANA-DC02' -Credential $cred -ErrorAction Stop
Invoke-Command -Session $s2 -ScriptBlock {
  '--- ADForest ---'
  (Get-DscResource -Name ADForest -Module ActiveDirectoryDsc -Syntax) -join "`n" | Write-Output
  '--- ADDomainController ---'
  (Get-DscResource -Name ADDomainController -Module ActiveDirectoryDsc -Syntax) -join "`n" | Write-Output
} -ErrorAction Stop | Write-Output
Remove-PSSession $s2
Write-Output 'DONE'
