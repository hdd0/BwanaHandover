$ErrorActionPreference = 'Continue'
Write-Output '=== BWANA DIRECTORY VERIFICATION ==='
$root = 'DC=ad,DC=bwanakhasu,DC=one'
$ou = Get-ADOrganizationalUnit -LDAPFilter '(name=Bwana)' -SearchBase $root
if ($ou) {
    Write-Output ('BASE-OU: ' + $ou.DistinguishedName)
    $kids = Get-ADOrganizationalUnit -LDAPFilter '(objectClass=organizationalUnit)' -SearchBase $ou.DistinguishedName -SearchScope OneLevel
    Write-Output ('CHILD-OUS (' + $kids.Count + '): ' + (($kids | Select-Object -ExpandProperty Name | Sort-Object) -join ', '))
} else { Write-Output 'BASE-OU: MISSING' }

$groups = Get-ADGroup -LDAPFilter '(cn=Bwana-*)' -SearchBase $root
Write-Output ('GROUPS (' + $groups.Count + '): ' + (($groups | Select-Object -ExpandProperty Name | Sort-Object) -join ', '))

$users = Get-ADUser -LDAPFilter '(sAMAccountName=hd)' -SearchBase $root -Properties memberOf
if ($users) {
    Write-Output ('USER: ' + $users.SamAccountName + ' enabled=' + $users.Enabled)
    Write-Output ('MEMBER-OF: ' + (($users.memberOf | ForEach-Object { ($_ -split ',')[0] }) -join ', '))
} else { Write-Output 'USER hd: MISSING' }
