$ErrorActionPreference = 'Continue'
$share = 'BwanaBackups'
$root = 'C:\BwanaBackups'
$sid = (Get-Content 'C:\Users\howar\AppData\Local\Temp\opencode\bwana-admins-sid.txt' -Raw).Trim()
New-Item -ItemType Directory -Force -Path $root | Out-Null
if (Get-SmbShare -Name $share -ErrorAction SilentlyContinue) {
  Remove-SmbShare -Name $share -Force
  Write-Output 'SHARE-REMOVED'
}
New-SmbShare -Name $share -Path $root -FullAccess "*$sid" -Description 'Bwana AD backup target' | Out-Null
Write-Output 'SHARE-CREATED'
# NT AUTHORITY\SYSTEM needs explicit NTForm
$acl = Get-Acl $root
$sys = New-Object System.Security.Principal.NTAccount('NT AUTHORITY','SYSTEM')
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sys,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
$acl.SetAccessRule($rule)
Set-Acl -Path $root -AclObject $acl
Write-Output 'ACL-SYSTEM-SET'
Get-SmbShare -Name $share | Select-Object Name, Path | Format-Table -AutoSize | Out-String | Write-Output
(Get-SmbShareAccess -Name $share | Select-Object AccountName, AccessControlType, AccessRight | Format-Table -AutoSize | Out-String) | Write-Output
Write-Output 'DONE'
