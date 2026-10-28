$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content 'C:\STEP\BwanaAD\scripts\test.ps1' -Raw)))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  [IO.File]::WriteAllText('C:\test.ps1', [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B)))
  & 'C:\test.ps1'
  Write-Output ('EXITCODE=' + $LASTEXITCODE)
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
