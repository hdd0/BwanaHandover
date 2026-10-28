$ErrorActionPreference = 'Continue'
$root = 'C:\BwanaBackups'
$share = 'BwanaBackups'
$pw = 'BwBk!2026#Svc' + (Get-Random -Minimum 1000 -Maximum 9999)
$user = 'BwanaBackupSvc'
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
if (-not (Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $user -Password $sec -Description 'Bwana AD backup service account' -PasswordNeverExpires $true | Out-Null
  Write-Output 'USER-CREATED'
} else {
  Set-LocalUser -Name $user -Password $sec -PasswordNeverExpires $true | Out-Null
  Write-Output 'USER-UPDATED'
}
$nt = New-Object System.Security.Principal.NTAccount($user)
$acl = Get-Acl $root
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($nt,'Modify','ContainerInherit,ObjectInherit','None','Allow')
$acl.SetAccessRule($rule)
Set-Acl -Path $root -AclObject $acl
Write-Output 'ACL-SET'
Grant-SmbShareAccess -Name $share -AccountName $nt -AccessRight Change -Force | Out-Null
Write-Output 'SHARE-ACCESS-SET'
$secure = ConvertTo-SecureString $pw -AsPlainText -Force
$secure | ConvertFrom-SecureString | Set-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Force
Write-Output 'CRED-SAVED'
Get-SmbShareAccess -Name $share | Select-Object AccountName, AccessRight | Format-Table -AutoSize | Out-String | Write-Output
Write-Output 'DONE'
