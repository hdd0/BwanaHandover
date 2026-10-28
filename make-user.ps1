$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  $usersOu = 'OU=Users,OU=Bwana,DC=ad,DC=bwanakhasu,DC=one'
  $pw = ConvertTo-SecureString 'BwanaLab!2026#Temp' -AsPlainText -Force
  if (-not (Get-ADUser -Filter 'SamAccountName -eq "hd"' -ErrorAction SilentlyContinue)) {
    New-ADUser -Name 'Howard Jambo' -SamAccountName 'hd' -UserPrincipalName 'hd@ad.bwanakhasu.one' `
      -Path $usersOu -AccountPassword $pw -Enabled $true -PasswordNeverExpires $true `
      -ChangePasswordAtLogon $false -GivenName 'Howard' -Surname 'Jambo' -Title 'Systems Engineer' -ErrorAction Stop
    Write-Output 'USER-CREATED hd'
  } else { Write-Output 'USER-EXISTS hd' }
  foreach ($g in @('Bwana-Admins','Bwana-Network','Bwana-Security')) {
    Add-ADGroupMember -Identity $g -Members 'hd' -ErrorAction SilentlyContinue
  }
  Write-Output ('GROUPS=' + ((Get-ADUser -Filter 'SamAccountName -eq "hd"' -Properties memberOf).memberOf -join ' | '))
  Write-Output '--- OU TREE ---'
  (Get-ADOrganizationalUnit -SearchBase 'OU=Bwana,DC=ad,DC=bwanakhasu,DC=one' -SearchScope OneLevel | Select-Object -ExpandProperty Name | Sort-Object) -join ', '
  Write-Output ('GROUPCOUNT=' + (Get-ADGroup -Filter 'GroupName -like "Bwana-*"' | Measure-Object).Count)
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
