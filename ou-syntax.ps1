$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
  (Get-DscResource -Name ADOrganizationalUnit -Module ActiveDirectoryDsc -Syntax) -join "`n"
  '--- ADGroup ---'
  (Get-DscResource -Name ADGroup -Module ActiveDirectoryDsc -Syntax) -join "`n"
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
