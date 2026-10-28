$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$dsec = ((Get-Content 'C:\STEP\unattend\secrets\dsrm.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$upn = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
try {
  $s = New-PSSession -VMName 'BWANA-DC02' -Credential $upn -EA Stop
  Write-Output ('UPN-OK host=' + (Invoke-Command -Session $s -ScriptBlock { $env:COMPUTERNAME }))
  Remove-PSSession $s
} catch { Write-Output ('UPN-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
