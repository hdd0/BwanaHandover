$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Write-Output 'attempting DC01...'
try {
  $s = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
  Write-Output 'DC01-SESSION-OK'
  $r = Invoke-Command -Session $s -ScriptBlock { whoami } -ErrorAction Stop
  Write-Output ('DC01-WHOAMI=' + $r)
  Remove-PSSession $s
} catch { Write-Output ('DC01-FAIL: ' + $_.Exception.Message) }
Write-Output 'DONE'
