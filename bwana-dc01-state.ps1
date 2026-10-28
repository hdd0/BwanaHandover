$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
try {
  Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
    'MOF-EXISTS=' + (Test-Path 'C:\DSC\MOF\localhost.mof')
    'ADDS=' + (Get-WindowsFeature AD-Domain-Services).Installed
    try { 'DOMAIN=' + (Get-ADDomain -ErrorAction Stop).DNSRoot } catch { 'DOMAIN=NONE' }
    try { 'LCM-STATE=' + (Get-DscLocalConfigurationManager).RebootNodeIfNeeded } catch { 'LCM=UNKNOWN' }
    '--- ADForest syntax ---'
    (Get-DscResource -Name ADForest -ModuleName ActiveDirectoryDsc -Syntax)
    '--- ADDomainController syntax ---'
    (Get-DscResource -Name ADDomainController -ModuleName ActiveDirectoryDsc -Syntax)
  } -ErrorAction Stop | Write-Output
} catch { Write-Output ('DC01-STATE: ' + $_.Exception.Message) }
