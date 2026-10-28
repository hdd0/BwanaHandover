$ErrorActionPreference = 'Continue'
$sec = ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$bsec = ((Get-Content 'C:\STEP\unattend\secrets\backupsvc.dpapi.txt' -Raw).Trim()) | ConvertTo-SecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($bsec))
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
$bcred = New-Object System.Management.Automation.PSCredential('BwanaBackupSvc', (ConvertTo-SecureString $plain -AsPlainText -Force))
$body = @'
param($User, $Pass)
$ErrorActionPreference = 'Continue'
# 1) clear any stale/failed SMB session to the host
& net.exe use \\192.168.150.1\BwanaBackups /delete /y 2>&1 | Out-Null
& net.exe use * /delete /y 2>&1 | Out-Null
Start-Sleep -Seconds 2
# 2) re-register the credential
& cmdkey.exe /delete:192.168.150.1 2>&1 | Out-Null
& cmdkey.exe /add:192.168.150.1 /user:$User /pass:$Pass 2>&1 | Out-Null
Start-Sleep -Seconds 2
& cmdkey.exe /list 2>&1 | Select-String '192.168.150.1' | ForEach-Object { Write-Output ('cmdkey: ' + $_) }
# 3) now try
Write-Output '--- md test ---'
& cmd.exe /c "md \\192.168.150.1\BwanaBackups\BWANA-DC01\ZZTEST" 2>&1 | ForEach-Object { Write-Output $_ }
Write-Output '--- write test ---'
try { Set-Content '\\192.168.150.1\BwanaBackups\BWANA-DC01\ZZTEST\f.txt' 'x' -EA Stop; Write-Output 'WRITE-OK' } catch { Write-Output ('WRITE-ERR: ' + $_.Exception.Message) }
& cmd.exe /c "rmdir /s /q \\192.168.150.1\BwanaBackups\BWANA-DC01\ZZTEST" 2>&1 | Out-Null
'@
$b64 = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($body))
Invoke-Command -VMName 'BWANA-DC01' -Credential $cred -ScriptBlock {
  param($B, $U, $P)
  $t = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($B))
  Set-Content 'C:\auth-test.ps1' $t -Force
  & 'C:\auth-test.ps1' -User $U -Pass $P
} -ArgumentList $b64, 'BwanaBackupSvc', $plain -ErrorAction Continue | Write-Output
Write-Output 'DONE'
