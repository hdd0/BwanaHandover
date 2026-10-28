$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$upn = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
Invoke-Command -VMName 'BWANA-DC02' -Credential $upn -ScriptBlock {
  Write-Output ('UP=' + ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime))
  & query.exe user 2>&1 | ForEach-Object { Write-Output $_ }
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
