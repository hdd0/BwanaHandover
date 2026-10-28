# Guest configuration for BWANA-MAIL-01.
# Pasted into the VM's own PowerShell via the VMConnect clipboard.
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

Write-Host '=== 1. Administrator password never expires ===' -ForegroundColor Cyan
Set-LocalUser -Name Administrator -PasswordNeverExpires $true
$u = Get-LocalUser Administrator
Write-Host ("  PasswordNeverExpires = {0}   PasswordLastSet = {1}" -f $u.PasswordNeverExpires, $u.PasswordLastSet)

Write-Host '=== 2. Computer name ===' -ForegroundColor Cyan
if ($env:COMPUTERNAME -ne 'BWANA-MAIL-01') {
    Write-Host "  current: $($env:COMPUTERNAME) -> renaming to BWANA-MAIL-01"
    Rename-Computer -NewName 'BWANA-MAIL-01' -Force
} else { Write-Host '  already named BWANA-MAIL-01' }

Write-Host '=== 3. Sysinternals Autologon ===' -ForegroundColor Cyan
$tools = 'C:\Tools'
New-Item -ItemType Directory -Path $tools -Force | Out-Null
$zip = "$tools\Autologon.zip"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri 'https://download.sysinternals.com/files/Autologon.zip' -OutFile $zip -UseBasicParsing -ErrorAction Stop
    Expand-Archive -Path $zip -DestinationPath $tools -Force
    Write-Host '  downloaded and extracted Autologon.exe' -ForegroundColor Green
}
catch {
    Write-Host "  download failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host '  falling back to setting the same registry values Autologon.exe writes.' -ForegroundColor Yellow
}

$w = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty -Path $w -Name 'AutoAdminLogon' -Value '1' -Type String
Set-ItemProperty -Path $w -Name 'DefaultUserName' -Value 'Administrator' -Type String
Set-ItemProperty -Path $w -Name 'DefaultDomainName' -Value 'BWANA-MAIL-01' -Type String
Set-ItemProperty -Path $w -Name 'AutoLogonCount' -Value '0' -Type String
# LogonCount 0 = log on unlimited times (lab box, per the standing rule).
Write-Host '  Winlogon autologon values written (AutoLogonCount 0 = unlimited)' -ForegroundColor Green

Write-Host '=== 4. Disable lock, screensaver and sleep ===' -ForegroundColor Cyan
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Desktop' -Name 'ScreenSaveActive' -Value '0'
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Desktop' -Name 'ScreenSaverIsSecure' -Value '0'
powercfg /change standby-timeout-ac 0 | Out-Null
powercfg /change monitor-timeout-ac 0 | Out-Null
powercfg /change hibernate-timeout-ac 0 | Out-Null
Write-Host '  screen lock and sleep disabled' -ForegroundColor Green

Write-Host '=== 5. Timezone ===' -ForegroundColor Cyan
try { Set-TimeZone -Id 'South Africa Standard Time'; Write-Host '  South Africa Standard Time' -ForegroundColor Green }
catch { Write-Host "  failed: $($_.Exception.Message)" -ForegroundColor Yellow }

Write-Host '=== 6. Verification ===' -ForegroundColor Cyan
$p = Get-ItemProperty $w
[PSCustomObject]@{
    ComputerName        = $env:COMPUTERNAME
    PasswordNeverExpires= (Get-LocalUser Administrator).PasswordNeverExpires
    AutoAdminLogon      = $p.AutoAdminLogon
    DefaultUserName     = $p.DefaultUserName
    DefaultDomainName   = $p.DefaultDomainName
    PartOfDomain        = (Get-CimInstance Win32_ComputerSystem).PartOfDomain
    Domain              = (Get-CimInstance Win32_ComputerSystem).Domain
    TimeZone            = (Get-TimeZone).Id
    AutologonExePresent = (Test-Path "$tools\Autologon.exe")
} | Format-List

Write-Host 'DONE-MARKER' -ForegroundColor Green
