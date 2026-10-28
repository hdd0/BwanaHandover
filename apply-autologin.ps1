$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = Get-Content 'C:\STEP\BwanaAD\scripts\enable-autologin.ps1' -Raw
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $P)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\enable-autologin.ps1' $t -Force
    & 'C:\enable-autologin.ps1' -UserName 'Administrator' -Password $P -Domain 'BWANA'
    Write-Output '--- verify ---'
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    'AutoAdminLogon=' + (Get-ItemPropertyValue $k AutoAdminLogon)
    'DefaultUserName=' + (Get-ItemPropertyValue $k DefaultUserName)
    'DefaultDomainName=' + (Get-ItemPropertyValue $k DefaultDomainName)
    'DefaultPasswordSet=' + ((Get-ItemPropertyValue $k DefaultPassword).Length -gt 0)
  } -ArgumentList $b64, $plain -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
