$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
Update-HostStorageCache
Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}, OperationalStatus | Format-Table -AutoSize | Out-String | Write-Output
Write-Output '--- partitions on the 100GB disk ---'
$d = Get-Disk | Where-Object { $_.Size -gt 80GB -and $_.Size -lt 120GB } | Select-Object -First 1
if ($d) { Get-Partition -DiskNumber $d.Number | Select-Object PartitionNumber, DriveLetter, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}}, Type | Format-Table -AutoSize | Out-String | Write-Output }
Write-Output '--- all volumes ---'
Get-Volume | Select-Object DriveLetter, FileSystemLabel, FileSystem, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize | Out-String | Write-Output
Write-Output '--- try format explicitly ---'
$p = Get-Partition -DriveLetter S -EA SilentlyContinue
if ($p) {
  try {
    Format-Volume -Partition $p -FileSystem NTFS -NewFileSystemLabel 'BWANABACKUP' -Confirm:$false -Force -ErrorAction Stop | Out-Null
    Write-Output 'FORMAT-OK'
  } catch { Write-Output ('FORMAT-ERR: ' + $_.Exception.Message) }
}
Get-Volume -DriveLetter S -EA SilentlyContinue | Select-Object DriveLetter, FileSystem, FileSystemLabel, @{n='SizeGB';e={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize | Out-String | Write-Output
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\disk-diag.ps1' $t -Force
    & 'C:\disk-diag.ps1'
  } -ArgumentList $b64 -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
