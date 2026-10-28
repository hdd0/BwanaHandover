$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Get-WinEvent -LogName 'Microsoft-Windows-TaskScheduler/Operational' -MaxEvents 40 -EA SilentlyContinue |
    Where-Object { $_.TimeCreated -ge (Get-Date).AddMinutes(-90) } |
    Select-Object TimeCreated, Id, @{n='Msg';e={$_.Message.Substring(0,[Math]::Min(180,$_.Message.Length))}} |
    Format-Table -AutoSize -Wrap | Out-String | Write-Output
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
