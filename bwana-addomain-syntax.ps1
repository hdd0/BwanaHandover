$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$s2 = New-PSSession -VMName 'BWANA-DC02' -Credential $cred -ErrorAction Stop
Invoke-Command -Session $s2 -ScriptBlock {
  (Get-DscResource -Name ADDomain -Module ActiveDirectoryDsc -Syntax) -join "`n" | Write-Output
} -ErrorAction Stop | Write-Output
Remove-PSSession $s2
Write-Output 'DONE'
