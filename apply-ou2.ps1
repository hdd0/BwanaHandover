$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$ouText = Get-Content -Path 'C:\STEP\BwanaAD\dsc\ActiveDirectory\BwanaOU.ps1' -Raw
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($Cfg)
  Set-Content -Path 'C:\DSCOU\BwanaOU.ps1' -Value $Cfg -Force
  . 'C:\DSCOU\BwanaOU.ps1'
  $cd = @{ AllNodes = @(@{ NodeName = 'localhost'; PSDscAllowPlainTextPassword = $true; PSDscAllowDomainUser = $true }) }
  Remove-Item 'C:\DSCOU\MOF' -Recurse -Force -ErrorAction SilentlyContinue
  BwanaOU -DomainName 'ad.bwanakhasu.one' -ConfigurationData $cd -OutputPath 'C:\DSCOU\MOF' | Out-Null
  Write-Output ('MOF-FILES=' + (Get-ChildItem 'C:\DSCOU\MOF' -Recurse -Filter *.mof).Count)
  Start-DscConfiguration -Path 'C:\DSCOU\MOF' -Force -Wait -Verbose
  Write-Output 'APPLY-WAIT-DONE'
} -ArgumentList $ouText -ErrorAction Continue | Select-Object -Last 60 | Write-Output
Write-Output 'DONE'
