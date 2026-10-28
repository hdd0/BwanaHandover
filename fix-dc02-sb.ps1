$ErrorActionPreference = 'Continue'
Stop-VM -Name 'BWANA-DC02' -TurnOff -Force
Start-Sleep -Seconds 5
Set-VMFirmware -VMName 'BWANA-DC02' -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows
Write-Output ('DC02 template=' + (Get-VMFirmware -VMName BWANA-DC02).SecureBootTemplate)
Start-VM -Name 'BWANA-DC02'
Write-Output 'DC02-STARTED'
Start-Sleep -Seconds 100
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC02' -Credential $cred -ScriptBlock {
  Write-Output ('HOST=' + $env:COMPUTERNAME + ' DOMAIN=' + (Get-ADDomain).DNSRoot)
  Write-Output ('NTDS=' + (Get-Service NTDS).Status)
} -ErrorAction Continue | Write-Output
