$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- procs ---'
  Get-Process wbadmin, powershell, VSS, svchost -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -in @('wbadmin','powershell') } |
    Select-Object Name, Id, CPU, StartTime | Format-Table -AutoSize | Out-String | Write-Output
  Write-Output '--- wbadmin jobs ---'
  & wbadmin.exe get jobs 2>&1 | Select-Object -Last 12 | ForEach-Object { Write-Output $_ }
  Write-Output '--- share SystemState growth ---'
  Get-ChildItem '\\192.168.150.1\BwanaBackups\BWANA-DC01\SystemState' -Recurse -File -EA SilentlyContinue |
    Measure-Object -Property Length -Sum |
    ForEach-Object { Write-Output ('files=' + $_.Count + ' bytes=' + $_.Sum) }
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
