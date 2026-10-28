$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- backup-related processes ---'
  Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -EA SilentlyContinue |
    Select-Object ProcessId, CreationDate, @{n='Cmd';e={$_.CommandLine.Substring(0,[Math]::Min(120,$_.CommandLine.Length))}} |
    Format-Table -AutoSize -Wrap | Out-String | Write-Output
  Get-Process wbadmin -EA SilentlyContinue | Select-Object Id, StartTime, CPU | Format-Table -AutoSize | Out-String | Write-Output
  Write-Output '--- deployed script version ---'
  Select-String -Path 'C:\backup-dc.ps1' -Pattern 'net use "BK|Do not re-add drive mapping' | Select-Object LineNumber, Line | Format-Table -AutoSize -Wrap | Out-String | Write-Output
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
