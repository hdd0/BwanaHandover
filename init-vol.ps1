$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
$letter = 'S'
Start-Sleep -Seconds 5
# find the new ~100GB disk (RAW / uninitialised)
$disk = Get-Disk | Where-Object { $_.Size -gt 80GB -and $_.Size -lt 120GB } | Select-Object -First 1
if (-not $disk) { Write-Output 'DISK-NOT-FOUND'; exit }
Write-Output ('disk=' + $disk.Number + ' sizeGB=' + [math]::Round($disk.Size/1GB,1) + ' style=' + $disk.PartitionStyle)
if ($disk.PartitionStyle -eq 'RAW') {
  Initialize-Disk -Number $disk.Number -PartitionStyle GPT -Confirm:$false | Out-Null
  Write-Output 'INITIALIZED GPT'
}
if (-not (Get-Partition -DiskNumber $disk.Number -EA SilentlyContinue)) {
  $p = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter $letter
  Format-Volume -Partition $p -FileSystem NTFS -NewFileSystemLabel 'BWANABACKUP' -Confirm:$false | Out-Null
  Write-Output ('FORMATTED ' + $letter + ':')
} else {
  $p = Get-Partition -DiskNumber $disk.Number | Select-Object -First 1
  if (-not $p.DriveLetter) {
    Set-Partition -DiskNumber $disk.Number -PartitionNumber $p.PartitionNumber -NewDriveLetter $letter | Out-Null
    Write-Output ('ASSIGNED ' + $letter + ':')
  } else { Write-Output ('OK volume already ' + $p.DriveLetter + ':') }
}
$vol = Get-Volume -DriveLetter $letter -EA SilentlyContinue
Write-Output ('VOLUME=' + $letter + ' freeGB=' + [math]::Round($vol.SizeRemaining/1GB,1) + ' label=' + $vol.FileSystemLabel)
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\init-vol.ps1' $t -Force
    & 'C:\init-vol.ps1'
  } -ArgumentList $b64 -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
