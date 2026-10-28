$ErrorActionPreference = 'Continue'
$fw = Get-VMFirmware -VMName 'BWANA-DC02'
Write-Host "Property type of EnableSecureBoot: $($fw.EnableSecureBoot.GetType().FullName)"
Write-Host "Raw value: [$($fw.EnableSecureBoot)]  IsNullOrEmpty: $([string]::IsNullOrEmpty($fw.EnableSecureBoot))"
Write-Host "Template : [$($fw.SecureBootTemplate)]"
Write-Host ""
# The Hyper-V module returns $null for EnableSecureBoot on Gen2 when SecureBoot is off in some builds.
# Cross-check by listing the actual firmware properties
$fw | Get-Member -MemberType Properties | Select-Object Name,Definition | Format-Table -AutoSize
