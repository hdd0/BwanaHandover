$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$path = '\\192.168.150.1\BwanaBackups'
try {
  New-Item -Path (Join-Path $path ('probe-' + $env:COMPUTERNAME + '.txt')) -Value 'backup-probe' -Force -ErrorAction Stop | Out-Null
  Write-Output ('SHARE-WRITE-OK: ' + $path)
  Get-ChildItem $path -Filter 'probe-*.txt' | Select-Object -ExpandProperty Name
} catch { Write-Output ('SHARE-ERR: ' + $_.Exception.Message) }
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('--- ' + $vm + ' ---')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\probe.ps1' $t -Force
    & 'C:\probe.ps1'
  } -ArgumentList $b64 -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
