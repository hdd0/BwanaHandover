$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- wbadmin get status ---'
  & wbadmin.exe get status 2>&1 | Select-Object -Last 20 | ForEach-Object { Write-Output $_ }
  Write-Output '--- vss list shadows ---'
  & vssadmin.exe list shadows 2>&1 | Select-Object -Last 15 | ForEach-Object { Write-Output $_ }
  Write-Output '--- SystemRestore / vss writers state ---'
  & vssadmin.exe list writers 2>&1 | Select-String -Pattern 'NTDS|Writer name|State:' | Select-Object -First 8 | ForEach-Object { Write-Output $_ }
  Write-Output '--- local stage SystemState ---'
  Get-ChildItem 'C:\BwanaBackupStage\SystemState' -Recurse -File -EA SilentlyContinue | Measure-Object | ForEach-Object { Write-Output ('local files=' + $_.Count) }
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
