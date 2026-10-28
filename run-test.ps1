$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = Get-Content 'C:\STEP\BwanaAD\scripts\test.ps1' -Raw
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $b = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content -Path 'C:\test.ps1' -Value $b -Force
  & 'C:\test.ps1'
  Write-Output ('EXITCODE=' + $LASTEXITCODE)
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
