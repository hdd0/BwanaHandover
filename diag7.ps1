$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
function Try-Wb($label, $argStr, $target) {
  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Write-Output ("--- $label : $argStr")
  $p = Start-Process wbadmin.exe -ArgumentList $argStr -Wait -NoNewWindow -PassThru -RedirectStandardOutput 'C:\w.txt' -RedirectStandardError 'C:\we.txt'
  $out = Get-Content 'C:\w.txt' -EA SilentlyContinue
  $errLine = $out | Where-Object { $_ -match 'ERROR|error|Backup operation|completed|failed' } | Select-Object -First 3
  Write-Output ('exit=' + $p.ExitCode)
  $errLine | ForEach-Object { Write-Output ('  ' + $_) }
  Write-Output ('files=' + (Get-ChildItem $target -Recurse -File -EA SilentlyContinue | Measure-Object).Count)
}
$t1 = '\\192.168.150.1\BwanaBackups\BWANA-DC01\SS-allcritical'
Try-Wb 'allCritical-only' ('start backup -backupTarget:"' + $t1 + '" -allCritical') $t1
$t2 = '\\192.168.150.1\BwanaBackups\BWANA-DC01\SS-include'
Try-Wb 'include-only' ('start backup -backupTarget:"' + $t2 + '" -include:SystemState') $t2
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag7.ps1' $t -Force
  & 'C:\diag7.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
