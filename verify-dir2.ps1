$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  $q = [char]39
  $ou = Get-ADOrganizationalUnit -Filter ($q + 'Bwana' + $q) -SearchBase ('DC=ad,DC=bwanakhasu,DC=one')
  $kids = Get-ADOrganizationalUnit -Filter '*' -SearchBase $ou.DistinguishedName -SearchScope OneLevel
  Write-Output ('CHILD-OUS(' + $kids.Count + ')=' + (($kids | Select-Object -ExpandProperty Name | Sort-Object) -join ', '))
  $all = Get-ADGroup -Filter '*' -Properties GroupName
  $bw = $all | Where-Object { $_.GroupName -like 'Bwana-*' }
  Write-Output ('GROUPS(' + $bw.Count + ')=' + (($bw | Select-Object -ExpandProperty GroupName | Sort-Object) -join ', '))
} -ErrorAction Continue | Write-Output
Write-Output 'DONE'
