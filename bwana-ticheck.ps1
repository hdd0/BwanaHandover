$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$s = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
Invoke-Command -Session $s -ScriptBlock {
  $ti = Get-Process -Name TiWorker -ErrorAction SilentlyContinue
  if ($ti) { 'TIWORKER cpu=' + $ti.CPU } else { 'TIWORKER-GONE' }
  try { 'ADDS=' + (Get-WindowsFeature AD-Domain-Services -ErrorAction Stop).Installed } catch { 'ADDS-QUERY-HUNG' }
} -ErrorAction Stop | Write-Output
Remove-PSSession $s
Write-Output 'DONE'
