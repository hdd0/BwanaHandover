$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
$letter = 'S'
$v = Get-Volume -DriveLetter $letter -EA SilentlyContinue
if ($v -and -not $v.FileSystem) {
  $p = Get-Partition -DriveLetter $letter
  Format-Volume -Partition $p -FileSystem NTFS -NewFileSystemLabel 'BWANABACKUP' -Confirm:$false -Force | Out-Null
  Write-Output 'FORMATTED'
}
$v = Get-Volume -DriveLetter $letter -EA SilentlyContinue
Write-Output ('VOLUME=' + $letter + ' fs=' + $v.FileSystem + ' label=' + $v.FileSystemLabel + ' sizeGB=' + [math]::Round($v.Size/1GB,1) + ' freeGB=' + [math]::Round($v.SizeRemaining/1GB,1))
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  Write-Output ('=== ' + $vm + ' ===')
  Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    param($B)
    $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
    Set-Content 'C:\fmt-vol.ps1' $t -Force
    & 'C:\fmt-vol.ps1'
  } -ArgumentList $b64 -ErrorAction Continue | Write-Output
}
Write-Output 'DONE'
