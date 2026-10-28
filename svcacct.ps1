$ErrorActionPreference = 'Continue'
$root = 'C:\BwanaBackups'
$share = 'BwanaBackups'
# Dedicated local service account purely for backup writes (not a domain join, not an admin)
$pw = 'BwBk!2026#Svc' + (Get-Random -Minimum 1000 -Maximum 9999)
$user = 'BwanaBackupSvc'
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
  Set-LocalUser -Name $user -Password $sec -PasswordNeverExpires $true | Out-Null
  Write-Output 'USER-UPDATED'
} else {
  New-LocalUser -Name $user -Password $sec -PasswordNeverExpires $true -UserMayNotChangePassword $true -Description 'Bwana AD backup service account' | Out-Null
  Write-Output 'USER-CREATED'
}
# Least privilege: Modify on the backup folder only
$acl = Get-Acl $root
$nt = New-Object System.Security.Principal.NTAccount($user)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($nt,'Modify','ContainerInherit,ObjectInherit','None','Allow')
$acl.SetAccessRule($rule)
Set-Acl -Path $root -AclObject $acl
Grant-SmbShareAccess -Name $share -AccountName $nt -AccessRight Modify -Force | Out-Null
# Persist the credential for the DCs, DPAPI-encrypted per-user
$secure = ConvertTo-SecureString $pw -AsPlainText -Force
$secure | ConvertFrom-SecureString | Set-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Force
Write-Output 'CRED-SAVED-DPAPI'
Get-SmbShareAccess -Name $share | Select-Object AccountName, AccessRight | Format-Table -AutoSize | Out-String | Write-Output
Write-Output 'DONE'
