$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
$u = 'BwanaBackupSvc'
& net.exe localgroup 'Backup Operators' $u /add 2>&1 | ForEach-Object { Write-Output $_ }
Write-Output '--- members now ---'
& net.exe localgroup 'Backup Operators' 2>&1 | Select-Object -Last 12 | ForEach-Object { Write-Output $_ }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\add-bo.ps1' $t -Force
    & 'C:\add-bo.ps1'
  } -ArgumentList $b64 -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
