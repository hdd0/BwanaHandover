$ErrorActionPreference = 'Continue'

# --- Recover lab admin credential from host DPAPI store (never printed) ---
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$cred = $null
if (Test-Path $secFile) {
    $sec = ConvertTo-SecureString ((Get-Content $secFile -Raw).Trim())
    $cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
    Write-Output ("CREDENTIAL: recovered DPAPI secret, user=" + $cred.UserName + ", passwordLength=" + $cred.GetNetworkCredential().Password.Length)
}
else { Write-Output 'CREDENTIAL: MISSING admin.dpapi.txt' }

if (-not $cred) { exit 1 }

# --- Probe each candidate Windows guest over PowerShell Direct ---
foreach ($vm in @('BWANA-DC01', 'BWANA-DC02', 'BWANA-OKD-01')) {
    Write-Output ''
    Write-Output ("=== " + $vm + " ===")
    try {
        $s = New-PSSession -VMName $vm -Credential $cred -ErrorAction Stop
    }
    catch {
        Write-Output ("  PowerShell Direct: NOT AVAILABLE (" + $_.Exception.Message.Split([Environment]::NewLine)[0] + ")")
        continue
    }
    try {
        $r = Invoke-Command -Session $s -ScriptBlock {
            $os = Get-CimInstance Win32_OperatingSystem
            [pscustomobject]@{
                Computer   = $env:COMPUTERNAME
                Product    = $os.Caption
                Version    = $os.Version
                Build      = $os.BuildNumber
                Domain     = (Get-CimInstance Win32_ComputerSystem).PartOfDomain
                MemGB      = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
                AutoLogon  = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -EA SilentlyContinue).AutoAdminLogon
                LockPolicy = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System\Power' -Name PromptPasswordOnResume -EA SilentlyContinue).PromptPasswordOnResume
                SaverOn    = (Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -EA SilentlyContinue).ScreenSaveActive
            }
        }
        $r | Format-List | Out-String | ForEach-Object { $_.TrimEnd() } | Write-Output
    }
    catch { Write-Output ("  Session query failed: " + $_.Exception.Message.Split([Environment]::NewLine)[0]) }
    finally { Remove-PSSession $s -ErrorAction SilentlyContinue }
}