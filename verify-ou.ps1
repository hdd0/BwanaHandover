$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Start-Sleep -Seconds 45
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  Write-Output '--- OUs under Bwana ---'
  $b = Get-ADOrganizationalUnit -Filter 'Name -eq "Bwana"' -SearchBase 'DC=ad,DC=bwanakhasu,DC=one'
  if ($b) {
    (Get-ADOrganizationalUnit -SearchBase $b.DistinguishedName -SearchScope OneLevel |
      Select-Object -ExpandProperty Name | Sort-Object) -join ', '
  } else { 'BASE-OU-MISSING' }
  Write-Output '--- Groups ---'
  $g = Get-ADGroup -Filter 'GroupName -like "Bwana-*"' -SearchBase 'DC=ad,DC=bwanakhasu,DC=one' | Sort-Object GroupName
  Write-Output ('count=' + $g.Count)
  ($g | Select-Object -ExpandProperty GroupName) -join ', '
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
