$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
$s = ((Get-Content 'C:\BwanaSharePw.txt' -Raw)).Trim() | ConvertTo-SecureString
& net.exe use Y: /delete /y 2>&1 | Out-Null
& net.exe use * /delete /y 2>&1 | Out-Null
Start-Sleep -Seconds 2
foreach ($u in @('192.168.150.1\BwanaBackupSvc','BwanaBackupSvc')) {
  $c = New-Object System.Management.Automation.PSCredential($u, $s)
  Write-Output ('--- persist as ' + $u)
  try {
    New-PSDrive -Name 'Y' -PSProvider FileSystem -Root '\\192.168.150.1\BwanaBackups' -Credential $c -Persist -Scope Global -EA Stop | Out-Null
    Write-Output '  PERSIST-MAP-OK'
    robocopy 'Y:\' 'C:\probe-y' /E /R:1 /W:3 /NFL /NDL /NP | Out-Null
    Write-Output ('  robocopy-rc=' + $LASTEXITCODE)
    Write-Output ('  files=' + (Get-ChildItem 'C:\probe-y' -Recurse -File -EA SilentlyContinue | Measure-Object).Count)
    Remove-PSDrive 'Y' -Force -Persist -EA SilentlyContinue
    break
  } catch { Write-Output ('  FAIL: ' + $_.Exception.Message) }
}
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\persist2.ps1' $t -Force
  & 'C:\persist2.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
