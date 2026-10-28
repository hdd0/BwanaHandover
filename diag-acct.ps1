$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
Write-Output ('COMPUTERNAME=' + $env:COMPUTERNAME)
Write-Output '--- local users matching Bwana ---'
Get-LocalUser -EA SilentlyContinue | Where-Object { $_.Name -like '*Bwana*' } |
  Select-Object Name, Enabled, PasswordRequired | Format-Table -AutoSize | Out-String | Write-Output
Write-Output '--- net user ---'
& net.exe user BwanaBackupSvc 2>&1 | Select-Object -First 8 | ForEach-Object { Write-Output $_ }
Write-Output '--- Backup Operators members ---'
Get-LocalGroupMember -Group 'Backup Operators' -EA SilentlyContinue |
  Select-Object Name, ObjectClass | Format-Table -AutoSize | Out-String | Write-Output
Write-Output '--- secedit export test ---'
$t = Join-Path $env:TEMP 'secx.inf'
$o = & secedit.exe /export /cfg $t /areas SECURITYPOLICY 2>&1
$o | ForEach-Object { Write-Output $_ }
Write-Output ('rc=' + $LASTEXITCODE + ' exists=' + (Test-Path $t))
Write-Output '--- whoami groups ---'
& whoami.exe /groups 2>&1 | Select-String 'Backup' | ForEach-Object { Write-Output $_ }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag7.ps1' $t -Force
  & 'C:\diag7.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
