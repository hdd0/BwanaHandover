$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- DSC STATUS ---'
  $st = Get-DscConfigurationStatus -ErrorAction SilentlyContinue
  if ($st) { $st | Select-Object Status, StartDate, NumberOfResources, NumberOfResourcesInDesiredState, NumberOfResourcesNotInDesiredState | Format-List | Out-String | Write-Output }
  else { 'no-status' }
  Write-Output '--- JOBS ---'
  Get-Job | Select-Object Id, Name, State | Format-Table -AutoSize | Out-String | Write-Output
  Write-Output '--- JOB RECEIVE ---'
  Get-Job | Receive-Job -ErrorAction SilentlyContinue | Select-Object -Last 25 | Out-String | Write-Output
  Write-Output '--- DSC OPERATIONAL ERRORS ---'
  Get-WinEvent -LogName 'Microsoft-Windows-DSC/Operational' -MaxEvents 60 -ErrorAction SilentlyContinue |
    Where-Object { $_.LevelDisplayName -eq 'Error' } |
    Select-Object -First 5 TimeCreated, Id, Message | Format-List | Out-String | Write-Output
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
