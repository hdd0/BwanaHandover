$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
try {
  $s = New-PSSession -VMName 'BWANA-DC02' -Credential $cred -ErrorAction Stop
  Write-Output 'DC02-SESSION-OK'
  $r = Invoke-Command -Session $s -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
  Write-Output ('DC02-HOST=' + $r)
  Remove-PSSession $s
} catch { Write-Output ('DC02: ' + $_.Exception.Message) }
