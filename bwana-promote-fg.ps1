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
    Set-Content -Path 'C:\DSC\BwanaDC.ps1' -Value $ConfigText -Force
    . 'C:\DSC\BwanaDC.ps1'
    $cd = @{ AllNodes = @(@{ NodeName = 'localhost'; PSDscAllowPlainTextPassword = $true }) }
    BwanaDC -Role FirstDC -DomainName 'ad.bwanakhasu.one' -NetBiosName 'BWANA' `
      -DomainAdminCredential $AdminCred -DSRMPassword $DsrmCred `
      -IPAddress '192.168.150.10' -ConfigurationData $cd -OutputPath 'C:\DSC\MOF' | Out-Null
    'MOF-COMPILED size=' + (Get-Item 'C:\DSC\MOF\localhost.mof').Length
    Start-Transcript -Path 'C:\DSC\apply.log' -Append | Out-Null
    Start-DscConfiguration -Path 'C:\DSC\MOF' -Force -Verbose
    Stop-Transcript | Out-Null
    'APPLY-FINISHED-NO-REBOOT'
  } -ArgumentList $dscText, $cred, $dsrmCred -ErrorAction Stop | Select-Object -Last 30 | Write-Output
} catch { Write-Output ('SESSION-ENDED: ' + $_.Exception.Message) }
