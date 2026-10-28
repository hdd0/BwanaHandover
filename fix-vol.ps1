$ErrorActionErrorAction = ''
$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
$letter = 'S'
$d = Get-Disk | Where-Object { $_.Size -gt 80GB -and $_.Size -lt 120GB } | Select-Object -First 1
if (-not $d) { Write-Output 'DISK-NOT-FOUND'; exit }
Write-Output ('cleaning disk ' + $d.Number)
Clear-Disk -Number $d.Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
$d = Get-Disk -Number $d.Number
# MBR gives a single simple primary partition - no MSR entry to trip over
Initialize-Disk -Number $d.Number -PartitionStyle MBR -Confirm:$false
$p = New-Partition -DiskNumber $d.Number -UseMaximumSize -DriveLetter $letter -IsActive
Format-Volume -Partition $p -FileSystem NTFS -NewFileSystemLabel 'BWANABACKUP' -Confirm:$false -Force | Out-Null
Start-Sleep -Seconds 2
$pp = Get-Partition -DriveLetter $letter
Write-Output ('PARTITION type=' + $pp.Type + ' sizeGB=' + [math]::Round($pp.Size/1GB,1))
$v = Get-Volume -DriveLetter $letter
Write-Output ('VOLUME fs=' + $v.FileSystem + ' label=' + $v.FileSystemLabel + ' sizeGB=' + [math]::Round($v.Size/1GB,1) + ' freeGB=' + [math]::Round($v.SizeRemaining/1GB,1))
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\fix-vol.ps1' $t -Force
    & 'C:\fix-vol.ps1'
  } -ArgumentList $b64 -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
