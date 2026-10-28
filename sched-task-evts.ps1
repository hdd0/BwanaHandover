$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' -MaxEvents 3000 -EA SilentlyContinue |
    Where-Object { $_.Message -match 'Bwana-AD-Backup' } |
    Select-Object -First 12 TimeCreated, Id, @{n='Msg';e={($_.Message -split "`n")[0]}} |
    Format-Table -AutoSize | Out-String | Write-Output
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
