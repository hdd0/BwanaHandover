$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$ouText = Get-Content -Path 'C:\STEP\BwanaAD\dsc\ActiveDirectory\BwanaOU.ps1' -Raw
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($Cfg)
  New-Item -ItemType Directory -Force -Path 'C:\DSCOU' | Out-Null
  Set-Content -Path 'C:\DSCOU\BwanaOU.ps1' -Value $Cfg -Force
  . 'C:\DSCOU\BwanaOU.ps1'
  $cd = @{ AllNodes = @(@{ NodeName = 'localhost'; PSDscAllowPlainTextPassword = $true; PSDscAllowDomainUser = $true }) }
  BwanaOU -DomainName 'ad.bwanakhasu.one' -ConfigurationData $cd -OutputPath 'C:\DSCOU\MOF' | Out-Null
  Write-Output 'MOF-OK'
  Start-DscConfiguration -Path 'C:\DSCOU\MOF' -Force -Verbose
  Write-Output 'APPLY-DONE'
} -ArgumentList $ouText -ErrorAction Continue | Select-Object -Last 25 | Write-Output
Write-Output 'DONE'
