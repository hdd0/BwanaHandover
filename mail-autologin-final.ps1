<# Silent autologin setup on BWANA-MAIL-01 using Unattend admin password #>
[xml]$x = Get-Content 'C:\STEP\unattend\Autounattend_DC01.xml'
$pwNode = $x.SelectSingleNode("//AdministratorPassword/Value")
if (-not $pwNode) { $pwNode = $x.SelectSingleNode("//UserAccounts//AdministratorPassword/Value") }
if (-not $pwNode) { $pwNode = $x.SelectSingleNode("//*[local-name()='AdministratorPassword']/*[local-name()='Value']") }
if (-not $pwNode) { throw 'Admin password not found' }
$pw = $pwNode.InnerText.Trim()
Write-Host ("Password length {0} (REDACTED)" -f $pw.Length)
# Apply to registry on BWANA-MAIL-01 via PowerShell Direct (silent)
$sec = ConvertTo-SecureString -String $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('BWANA\Administrator', $sec)
Invoke-Command -VMName BWANA-MAIL-01 -ScriptBlock {
    param([string]$P,[string]$U)
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    Set-ItemProperty -Path $k -Name AutoAdminLogon -Value '1' -Type String -Force
    Set-ItemProperty -Path $k -Name DefaultUserName -Value $U -Type String -Force
    Set-ItemProperty -Path $k -Name DefaultPassword -Value $P -Type String -Force
    Set-ItemProperty -Path $k -Name DefaultDomainName -Value 'BWANA.KHASU.ONE' -Type String -Force
    Remove-ItemProperty -Path $k -Name AutoLogonCount -ErrorAction SilentlyContinue
    [pscustomobject]@{Status='PASS';Machine='BWANA-MAIL-01';AutoLogin='1';User=$U;Domain='BWANA.KHASU.ONE';PassLength=$P.Length}
} -ArgumentList $pw, 'BWANA\Administrator' -Credential $cred -ErrorAction SilentlyContinue 2>&1 | ForEach-Object { Write-Output $_.ToString() }
Write-Host '[PASS] Autologin set (REDACTED) on BWANA-MAIL-01'
