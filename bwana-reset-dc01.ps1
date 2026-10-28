Restart-VM -Name 'BWANA-DC01' -Force
Write-Output 'DC01-RESET-SENT'
Start-Sleep -Seconds 90
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
try {
  $s = New-PSSession -VMName 'BWANA-DC01' -Credential $cred -ErrorAction Stop
  Write-Output 'DC01-SESSION-OK'
  Invoke-Command -Session $s -ScriptBlock { $env:COMPUTERNAME + ' ADDS=' + (Get-WindowsFeature AD-Domain-Services).Installed } -ErrorAction Stop | Write-Output
  Remove-PSSession $s
} catch { Write-Output ('DC01: ' + $_.Exception.Message) }
