$ErrorActionPreference = 'Continue'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ConvertTo-SecureString ((Get-Content $secFile -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)

foreach ($vm in @('BWANA-DC01', 'BWANA-DC02')) {
    Write-Output ("=== " + $vm + " ===")
    $s = $null
    try {
        $s = New-PSSession -VMName $vm -Credential $cred -ErrorAction Stop
    }
    catch { Write-Output "FAIL connect: $($_.Exception.Message)"; continue }

    try {
        Invoke-Command -Session $s -ScriptBlock {
            $w = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
            $p = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -EA SilentlyContinue
            $pp = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\Power' -EA SilentlyContinue
            $sys = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -EA SilentlyContinue
            $wl = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -EA SilentlyContinue
            $hklmDesk = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\Desktop' -EA SilentlyContinue
            $os = Get-CimInstance Win32_OperatingSystem
            $cs = Get-CimInstance Win32_ComputerSystem
            [pscustomobject]@{
                VM              = $env:COMPUTERNAME
                OS              = $os.Caption + ' build ' + $os.BuildNumber
                MemGB           = [math]::Round($cs.TotalPhysicalMemory/1GB,2)
                DomainRole      = $cs.DomainRole
                AutoAdminLogon  = $w.AutoAdminLogon
                DefaultUserName = $w.DefaultUserName
                DefaultDomainName = $w.DefaultDomainName
                PasswordPlaintext = ($w.DefaultPassword -is [string])
                NoLockScreen    = $p.NoLockScreen
                PromptOnResume  = $pp.PromptPasswordOnResume
                InactivityTimeout = $sys.InactivityTimeoutSecs
                DisableLockWorkstation = $wl.DisableLockWorkstation
                HKLMSaverActive = $hklmDesk.ScreenSaveActive
                HKLMSaverTimeout = $hklmDesk.ScreenSaveTimeOut
            } | Format-List
        }
    }
    catch { Write-Output "FAIL query: $($_.Exception.Message)" }
    finally { Remove-PSSession $s -ErrorAction SilentlyContinue }
}