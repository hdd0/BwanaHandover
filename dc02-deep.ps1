$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Write-Output '--- host worker events for DC02 (last 15 min) ---'
Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-Worker-Admin' -MaxEvents 60 -EA SilentlyContinue |
  Where-Object { $_.Message -match 'BWANA-DC02' -and $_.TimeCreated -ge (Get-Date).AddMinutes(-15) } |
  Select-Object TimeCreated, Id, @{n='Msg';e={$_.Message.Substring(0,[Math]::Min(160,$_.Message.Length))}} |
  Format-Table -AutoSize -Wrap | Out-String | Write-Output
Write-Output '--- fresh PS Direct attempt with detail ---'
try {
  $s = New-PSSession -VMName 'BWANA-DC02' -Credential $cred -ErrorAction Stop
  Write-Output 'SESSION-ESTABLISHED'
  $r = Invoke-Command -Session $s -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
  Write-Output ('HOST=' + $r)
  Remove-PSSession $s
} catch {
  Write-Output ('FAIL: ' + $_.Exception.GetType().FullName)
  Write-Output ('MSG: ' + $_.Exception.Message)
  if ($_.InnerException) { Write-Output ('INNER: ' + $_.InnerException.Message) }
}
Write-Output 'DONE'
