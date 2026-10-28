$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
$ErrorActionPreference = 'Continue'
$raw = Get-Content 'C:\BwanaSharePw.txt' -Raw
$s = ($raw).Trim() | ConvertTo-SecureString
$c = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', $s)
$c2 = New-Object System.Management.Automation.PSCredential('192.168.150.1\BwanaBackupSvc', $s)
& net.exe use BK: /delete /y 2>&1 | Out-Null
& net.exe use * /delete /y 2>&1 | Out-Null
Start-Sleep -Seconds 2
foreach ($cc in @($c, $c2)) {
  Write-Output ('--- New-PSDrive -Persist as ' + $cc.UserName)
  try {
    New-PSDrive -Name BK -PSProvider FileSystem -Root '\\192.168.150.1\BwanaBackups' -Credential $cc -Persist -Scope Global -EA Stop | Out-Null
    Write-Output '  PERSIST-MAP-OK'
    & cmd.exe /c "dir BK:\" 2>&1 | Select-Object -First 5 | ForEach-Object { Write-Output ('  ' + $_) }
    $rcOut = robocopy BK:\ 'C:\probe-bk' /E /R:1 /W:3 /NFL /NDL /NP 2>&1
    Write-Output ('  robocopy-rc=' + $LASTEXITCODE)
    Remove-PSDrive BK -Force -Persist -EA SilentlyContinue
    break
  } catch { Write-Output ('  FAIL: ' + $_.Exception.Message) }
}
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\persist-test.ps1' $t -Force
  & 'C:\persist-test.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
