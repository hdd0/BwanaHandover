$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- ADDefaultPasswordPolicy ---'
  try { (Get-DscResource -Name ADDefaultPasswordPolicy -Module ActiveDirectoryDsc -Syntax) -join "`n" | Write-Output } catch { Write-Output ('ERR: ' + $_.Exception.Message) }
  Write-Output '--- GroupPolicyDsc installed? ---'
  Write-Output ((Get-Module -ListAvailable -Name GroupPolicyDsc | Select-Object -First 1).Version)
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
