$ErrorActionPreference = 'Continue'
$root = 'C:\BwanaBackups'
$share = 'BwanaBackups'
$pw = 'BwBk!2026#Svc' + (Get-Random -Minimum 1000 -Maximum 9999)
$user = 'BwanaBackupSvc'
$sec = ConvertTo-SecureString $pw -AsPlainText -Force
if (-not (Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
  New-LocalUser -Name $user -Password $sec -Description 'Bwana AD backup service account' | Out-Null
  Write-Output 'USER-CREATED'
} else { Write-Output 'USER-EXISTS' }
$u = Get-LocalUser -Name $user
Write-Output ('USER-OK=' + $u.Name + ' enabled=' + $u.Enabled)
$nt = New-Object System.Security.Principal.NTAccount($user)
$acl = Get-Acl $root
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($nt,'Modify','ContainerInherit,ObjectInherit','None','Allow')
$acl.SetAccessRule($rule)
Set-Acl -Path $root -AclObject $acl
Write-Output 'ACL-SET'
Grant-SmbShareAccess -Name $share -AccountName $nt -AccessRight Change -Force | Out-Null
Write-Output 'SHARE-ACCESS-SET'
(ConvertTo-SecureString $pw -AsPlainText -Force) | ConvertFrom-SecureString | Set-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Force
Write-Output 'CRED-SAVED'
Get-SmbShareAccess -Name $share | Select-Object AccountName, AccessRight | Format-Table -AutoSize | Out-String | Write-Output
Write-Output 'DONE'
