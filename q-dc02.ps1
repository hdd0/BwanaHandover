$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
try {
  Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
    Write-Output '--- DSC STATUS ---'
    $st = $null; try { $st = Get-DscConfigurationStatus -ErrorAction Stop } catch { Write-Output 'no-status' }
    if ($st) { $st | Select-Object Status, StartDate, NumberOfResources, RebootRequested | Format-List | Out-String | Write-Output }
    Write-Output '--- JOBS ---'
    Get-Job | Select-Object Id, Name, State | Format-Table -AutoSize | Out-String | Write-Output
    Write-Output '--- SERVICING PROCS ---'
    Get-Process -Name TiWorker, TrustedInstaller, dism -ErrorAction SilentlyContinue |
      Select-Object Name, Id, CPU | Format-Table -AutoSize | Out-String | Write-Output
    Write-Output '--- CBS TAIL ---'
    Get-Content C:\Windows\Logs\CBS\CBS.log -Tail 3 -ErrorAction SilentlyContinue
  } -ErrorAction Continue | Write-Output
} catch { Write-Output ('QUERY-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
