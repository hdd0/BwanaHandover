$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Write-Output '--- DC02 Directory Service log (last 30 min, errors/warnings) ---'
try {
  Get-WinEvent -ComputerName '192.168.150.11' -Credential $cred -LogName 'Directory Service' -MaxEvents 60 -EA Stop |
    Where-Object { $_.TimeCreated -ge (Get-Date).AddMinutes(-40) -and $_.LevelDisplayName -match 'Error|Warning' } |
    Select-Object -First 8 TimeCreated, Id, LevelDisplayName, @{n='Msg';e={$_.Message.Substring(0,[Math]::Min(200,$_.Message.Length))}} |
    Format-Table -AutoSize -Wrap | Out-String | Write-Output
} catch { Write-Output ('DS-LOG-FAIL: ' + $_.Exception.Message) }
Write-Output '--- DC02 System log boot/services (last 30 min, errors) ---'
try {
  Get-WinEvent -ComputerName '192.168.150.11' -Credential $cred -LogName 'System' -MaxEvents 200 -EA Stop |
    Where-Object { $_.TimeCreated -ge (Get-Date).AddMinutes(-40) -and $_.LevelDisplayName -eq 'Error' } |
    Select-Object -First 8 TimeCreated, Id, @{n='Src';e={$_.ProviderName}}, @{n='Msg';e={$_.Message.Substring(0,[Math]::Min(160,$_.Message.Length))}} |
    Format-Table -AutoSize -Wrap | Out-String | Write-Output
} catch { Write-Output ('SYS-LOG-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
