$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$s = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
Write-Output 'SESSION-OK'
$r = Invoke-Command -Session $s -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
Write-Output ('HOST=' + $r)
Remove-PSSession $s
Write-Output 'DONE'
