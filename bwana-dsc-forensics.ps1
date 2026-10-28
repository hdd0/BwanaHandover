$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$s = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
Invoke-Command -Session $s -ScriptBlock {
  '--- DSC STATUS FULL ---'
  Get-DscConfigurationStatus | Select-Object Status, StartDate, Type, Mode, RebootRequested, NumberOfResources | Format-List | Out-String | Write-Output
  '--- RESOURCES STATUS ---'
  try { (Get-DscConfigurationStatus).ResourcesNotInDesiredState | Select-Object ResourceName, ConfigurationName | Format-Table -AutoSize | Out-String | Write-Output } catch { 'N/A' }
  '--- GUEST JOBS ---'
  Get-Job | Select-Object Name, State, HasMoreData | Format-Table -AutoSize | Out-String | Write-Output
  '--- JOB OUTPUT (if any) ---'
  Get-Job | Receive-Job -Keep 2>&1 | Select-Object -Last 20 | Out-String | Write-Output
  '--- DSC OPERATIONAL ERRORS (last 10) ---'
  Get-WinEvent -LogName 'Microsoft-Windows-DSC/Operational' -MaxEvents 40 -ErrorAction SilentlyContinue |
    Where-Object { $_.LevelDisplayName -match 'Error|Warning' } |
    Select-Object -First 10 TimeCreated, Id, Message | Format-List | Out-String | Write-Output
} -ErrorAction Stop | Write-Output
Remove-PSSession $s
Write-Output 'DONE'
