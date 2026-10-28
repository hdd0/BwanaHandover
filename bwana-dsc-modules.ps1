$ErrorActionPreference = 'Stop'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ((Get-Content $secFile -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      Install-PackageProvider -Name NuGet -Force -Confirm:$false | Out-Null
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
      foreach ($m in @('ActiveDirectoryDsc','NetworkingDsc','ComputerManagementDsc')) {
        if (-not (Get-Module -ListAvailable -Name $m)) { Install-Module -Name $m -Force -Confirm:$false }
      }
      (Get-Module -ListAvailable -Name @('ActiveDirectoryDsc','NetworkingDsc','ComputerManagementDsc') |
        Select-Object Name, Version | ForEach-Object { $_.Name + '=' + $_.Version }) -join '; '
    } -ErrorAction Stop
    Write-Output ($vm + ': ' + $r)
  } catch { Write-Output ($vm + ': FAILED: ' + $_.Exception.Message) }
}
