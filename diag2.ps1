$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$body = @'
function Try-Ifm($label, $lines) {
  $f = 'C:\ifm-' + $label + '.txt'
  ($lines -join "`r`n") | Set-Content -Path $f -Encoding ASCII -NoNewline
  Write-Output ("--- $label ---")
  $out = cmd.exe /c "ntdsutil.exe < $f" 2>&1
  $out | ForEach-Object { if ($_ -match '\S') { Write-Output $_ } }
  $d = 'C:\IFM-' + $label
  Write-Output ("EXISTS=" + (Test-Path (Join-Path $d 'NTDS.dit')))
}
if (Test-Path 'C:\IFM-A') { Remove-Item 'C:\IFM-A' -Recurse -Force -ErrorAction SilentlyContinue }
if (Test-Path 'C:\IFM-B') { Remove-Item 'C:\IFM-B' -Recurse -Force -ErrorAction SilentlyContinue }
Try-Ifm 'A' @('activate instances ntds','ifm','create full C:\IFM-A','quit','quit')
Try-Ifm 'B' @('activate instances ntds','ifm','create full C:\IFM-B /h','quit','quit')
Write-Output '=== wbadmin arg-array variant ==='
$ss = 'C:\WSB-Test'
New-Item -ItemType Directory -Force -Path $ss | Out-Null
$args = @('start','backup','-backupTarget:' + $ss,'-include:SystemState','-allCritical','-verbose')
& wbadmin.exe @args 2>&1 | Select-Object -Last 15 | ForEach-Object { Write-Output $_ }
Write-Output ('WB-FILES=' + (Get-ChildItem $ss -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count)
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\diag2.ps1' $t -Force
  & 'C:\diag2.ps1'
} -ArgumentList $b64 -ErrorAction Continue | Write-Output
Write-Output 'DONE'
