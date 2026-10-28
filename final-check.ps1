$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- log (full) ---'
  Get-Content 'C:\BwanaBackup.log' -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_ }
  Write-Output '--- wbadmin-out.txt ---'
  Get-Content 'C:\wbadmin-out.txt' -ErrorAction SilentlyContinue | Select-Object -Last 6 | ForEach-Object { Write-Output $_ }
  Write-Output '--- cmdkey list ---'
  & cmdkey.exe /list 2>&1 | Select-String -Pattern '192.168.150.1|BwanaBackupSvc' | ForEach-Object { Write-Output $_ }
} -ErrorAction Continue | Write-Output
Write-Output '=== share state ==='
Get-ChildItem C:\BwanaBackups -Directory -EA SilentlyContinue | ForEach-Object {
  $n = $_.Name
  $f = (Get-ChildItem $_.FullName -Recurse -File -EA SilentlyContinue | Measure-Object -Property Length -Sum)
  Write-Output ("{0}: files={1} sizeMB={2} manifest={3}" -f $n, $f.Count, [math]::Round($f.Sum/1MB,1), (Test-Path (Join-Path $_.FullName 'backup-manifest.json')))
}
Write-Output 'DONE'
