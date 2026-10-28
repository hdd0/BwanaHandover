$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $plain -AsPlainText -Force))
$body = Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B, $C)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\backup-dc.ps1' $t -Force
    & 'C:\backup-dc.ps1' -DCName $env:COMPUTERNAME -ShareRoot '\\192.168.150.1\BwanaBackups' -ShareCredential $C
  } -ArgumentList $b64, $bcred -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
