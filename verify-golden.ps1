Get-VM -Name 'BWANA-GOLDEN-SRC' | Select-Object Name,State,Uptime | Format-List | Out-String | Write-Output
Get-VMIntegrationService -VMName 'BWANA-GOLDEN-SRC' | Select-Object Name,Enabled,PrimaryStatusDescription | Format-Table -AutoSize | Out-String | Write-Output
Get-VMFirmware -VMName 'BWANA-GOLDEN-SRC' | Select-Object SecureBoot,SecureBootTemplate | Format-List | Out-String | Write-Output
