$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('192.168.150.1\BwanaBackupSvc', $bsec)
$body = @'
param($Share, $HostCred)
$sm = New-SmbMapping -LocalPath $Share -RemotePath $Share -Credential $HostCred -Persistent $false -ErrorAction SilentlyContinue
try {
  Set-Content -Path ($Share + '\probe.txt') -Value ('probe ' + $env:COMPUTERNAME + ' ' + (Get-Date -Format s)) -Force -ErrorAction Stop
  Write-Output ('SHARE-WRITE-OK: ' + (Get-Content ($Share + '\probe.txt')))
} catch { Write-Output ('SHARE-ERR: ' + $_.Exception.Message) }
Remove-SmbMapping -LocalPath $Share -Force -UpdateProfile -ErrorAction SilentlyContinue
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
$share = '\\192.168.150.1\BwanaBackups'
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('--- ' + $vm + ' ---')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $S, $HC)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\probe3.ps1' $t -Force
    & 'C:\probe3.ps1' -Share $S -HostCred $HC
  } -ArgumentList $b64, $share, $bcred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
