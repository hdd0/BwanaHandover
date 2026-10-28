$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock { Restart-Computer -Force } -EA SilentlyContinue
Write-Output 'REBOOT-SENT, waiting 150s...'
Start-Sleep -Seconds 150
Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
  Write-Output ('UP=' + ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime))
  Write-Output '--- console/interactive sessions (proves autologon) ---'
  & query.exe user 2>&1 | ForEach-Object { Write-Output $_ }
  Write-Output ('NTDS=' + (Get-Service NTDS -EA SilentlyContinue).Status)
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
