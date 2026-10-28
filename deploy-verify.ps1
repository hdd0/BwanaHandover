$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$local = Get-Content 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Raw
$lh = (Get-FileHash 'C:\STEP\BwanaAD\scripts\backup-dc.ps1' -Algorithm SHA256).Hash
Write-Output ('REPO-HASH=' + $lh)
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($local))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  [IO.File]::WriteAllText('C:\backup-dc.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
  Write-Output 'WRITTEN'
  $h = (Get-FileHash 'C:\backup-dc.ps1' -Algorithm SHA256).Hash
  Write-Output ('DC-HASH=' + $h)
  $n = Select-String -Path 'C:\backup-dc.ps1' -Pattern 'Do not re-add drive mapping' | Measure-Object | Select-Object -ExpandProperty Count
  Write-Output ('NOTE-PRESENT=' + ($n -gt 0))
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
