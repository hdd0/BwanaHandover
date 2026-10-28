<# Silent inspection of BWANA-MAIL-01 - no dialogs, password REDACTED #>
$un = [xml](Get-Content 'C:\STEP\BwanaMail\data\BWANA-MAIL-01-Autounattend.xml')
$node = $un.SelectSingleNode("//*[local-name()='Password']/*[local-name()='Value']")
if (-not $node) { $node = $un.SelectSingleNode("//*[local-name()='AdministratorPassword']/*[local-name()='Value']") }
if (-not $node) { $node = $un.SelectSingleNode("//*[contains(local-name(),'Password')]/*[local-name()='Value']") }
$pw = $node.InnerText.Trim()
$sec = ConvertTo-SecureString -String $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
Invoke-Command -VMName BWANA-MAIL-01 -ScriptBlock {
    Write-Output '=== RUNNING MAIL/EXCHANGE SERVICES ==='
    Get-Service | Where-Object { $_.Name -match 'Exchange|SMTP|Transport|Mail' } | Select-Object Name,Status,StartType | Format-Table -AutoSize | Out-String
    Write-Output '=== EXCHANGE PRESENCE ==='
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup') {
        (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup') | Select-Object MsiProductMajor,MsiProductMinor,MsiInstallPath | Format-List | Out-String
    } else { Write-Output 'Exchange NOT installed on BWANA-MAIL-01' }
    Write-Output '=== TRANSPORT RULES ==='
    try { Get-TransportRule -ResultSize 10 | Select-Object Name,State | Format-Table -AutoSize | Out-String } catch { Write-Output 'No Exchange transport-rule session available' }
    Write-Output '=== MAILBOXES ==='
    try { $mb = Get-Mailbox -ResultSize Unlimited; Write-Output ("Count: " + $mb.Count); $mb | Select-Object -First 10 Name,PrimarySmtpAddress | Format-Table -AutoSize | Out-String } catch { Write-Output 'No Exchange mailbox session available' }
    Write-Output '=== HOSTS / DNS SITES ==='
    try { Get-ADComputer -Filter "Name -like 'BWANA-MAIL*'" | Select-Object Name,IPv4Address | Format-Table -AutoSize | Out-String } catch {}
    Write-Output '=== OS / INSTALLED ROLES ==='
    (Get-CimInstance Win32_OperatingSystem).Caption
    Get-WindowsFeature -Name RSN-Role-Install, RSN-Role-RS, Web-Server | Select-Object Name,InstallState | Format-Table -AutoSize | Out-String
} -Credential $cred 2>&1 | ForEach-Object { $_.ToString() }
