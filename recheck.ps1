$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
try {
  Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
    Write-Output ('UP=' + ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime))
    & query.exe user 2>&1 | ForEach-Object { Write-Output $_ }
    Write-Output ('NTDS=' + (Get-Service NTDS -EA SilentlyContinue).Status)
  } -ErrorAction Stop | Write-Output
} catch { Write-Output ('NOT-READY: ' + $_.Exception.Message) }
Write-Output 'DONE'
