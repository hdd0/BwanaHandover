$ErrorActionPreference = 'Continue'

Write-Output '=== secret inventory (usernames/lengths only, no values) ==='
foreach ($f in @('admin.dpapi.txt', 'dsrm.dpapi.txt', 'backupsvc.dpapi.txt')) {
    $p = "C:\STEP\unattend\secrets\$f"
    if (Test-Path $p) {
        $sec = ConvertTo-SecureString ((Get-Content $p -Raw).Trim())
        $c = New-Object System.Management.Automation.PSCredential('x', $sec)
        Write-Output ("  " + $f + " -> passwordLength=" + $c.GetNetworkCredential().Password.Length)
    }
}
$u = Get-Content 'C:\STEP\unattend\secrets\dc-cred-user.txt' -Raw -ErrorAction SilentlyContinue
Write-Output ("  dc-cred-user.txt -> '" + $u.Trim() + "'")

$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())

# UPN form is known to work where the NetBIOS form is rejected
$candidates = @(
    'Administrator@ad.bwanakhasu.one',
    'ad.bwanakhasu.one\Administrator',
    'BWANA\Administrator',
    '.\Administrator'
)

foreach ($vm in @('BWANA-DC01', 'BWANA-DC02')) {
    Write-Output ''
    Write-Output ("=== " + $vm + " ===")
    $ok = $false
    foreach ($name in $candidates) {
        $cred = New-Object System.Management.Automation.PSCredential($name, $sec)
        try {
            $s = New-PSSession -VMName $vm -Credential $cred -ErrorAction Stop
            $r = Invoke-Command -Session $s -ScriptBlock {
                $os = Get-CimInstance Win32_OperatingSystem
                $cs = Get-CimInstance Win32_ComputerSystem
                [pscustomobject]@{
                    Computer  = $env:COMPUTERNAME
                    Product   = $os.Caption
                    Build     = $os.BuildNumber
                    Domain    = $cs.PartOfDomain
                    DomainRole= $cs.DomainRole
                    MemGB     = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                    AutoLogon = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -EA SilentlyContinue).AutoAdminLogon
                }
            }
            Write-Output ("  SUCCESS with '" + $name + "'")
            $r | Format-List | Out-String | ForEach-Object { $_.TrimEnd() } | Write-Output
            Remove-PSSession $s -EA SilentlyContinue
            $ok = $true
            break
        }
        catch {
            Write-Output ("  FAIL '" + $name + "': " + $_.Exception.Message.Split([Environment]::NewLine)[0])
        }
    }
    if (-not $ok) { Write-Output ("  NO WORKING CREDENTIAL for " + $vm) }
}