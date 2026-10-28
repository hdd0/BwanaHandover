$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  $b = Import-Clixml 'C:\BwanaSvcCred.xml'
  Write-Output '=== direct run ==='
  & 'C:\backup-dc.ps1' -DCName $env:COMPUTERNAME -ShareRoot '\\192.168.150.1\BwanaBackups' -ShareCredential $b -SkipSystemState
  Write-Output ('exit=' + $LASTEXITCODE)
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
