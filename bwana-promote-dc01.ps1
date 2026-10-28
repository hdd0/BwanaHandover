$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$dsrmFile = 'C:\STEP\unattend\secrets\dsrm.dpapi.txt'
$dsec = ((Get-Content $dsrmFile -Raw).Trim()) | ConvertTo-SecureString
$dsrmCred = New-Object System.Management.Automation.PSCredential('DSRM', $dsec)
$dscText = Get-Content -Path 'C:\STEP\BwanaAD\dsc\DomainControllers\BwanaDC.ps1' -Raw
try {
  Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    param($ConfigText, $AdminCred, $DsrmCred)
    New-Item -ItemType Directory -Force -Path 'C:\DSC' | Out-Null
    Set-Content -Path 'C:\DSC\BwanaDC.ps1' -Value $ConfigText -Force
    . 'C:\DSC\BwanaDC.ps1'
    $cd = @{ AllNodes = @(@{ NodeName = 'localhost'; PSDscAllowPlainTextPassword = $true }) }
    BwanaDC -Role FirstDC -DomainName 'ad.bwanakhasu.one' -NetBiosName 'BWANA' `
      -DomainAdminCredential $AdminCred -DSRMPassword $DsrmCred `
      -IPAddress '192.168.150.10' -ConfigurationData $cd -OutputPath 'C:\DSC\MOF' | Out-Null
    'MOF-COMPILED'
    [DscLocalConfigurationManager()]
    Configuration LCMBoot { Node localhost { Settings { RebootNodeIfNeeded = $true; ActionAfterReboot = 'ContinueConfiguration'; ConfigurationMode = 'ApplyAndMonitor' } } }
    LCMBoot -OutputPath 'C:\DSC\LCM' | Out-Null
    Set-DscLocalConfigurationManager -Path 'C:\DSC\LCM' -Force
    'LCM-SET'
    Start-Job -ScriptBlock { Start-DscConfiguration -Path 'C:\DSC\MOF' -Force } | Out-Null
    'DSC-STARTED-BACKGROUND (reboot imminent)'
  } -ArgumentList $dscText, $cred, $dsrmCred -ErrorAction Stop | Write-Output
} catch { Write-Output ('DC01-PROMOTE-TRIGGER: ' + $_.Exception.Message) }
