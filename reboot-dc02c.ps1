$ErrorActionPreference = 'Stop'
$n = 'BWANA-DC02'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
function Get-Sess([string]$vm) {
    $s = $null
    for ($i = 1; $i -le 8 -and -not $s; $i++) {
        try { $s = New-PSSession -VMName $vm -Credential $cred -ErrorAction Stop }
        catch { Write-Output "  psdirect attempt $i failed"; Start-Sleep -Seconds 20 }
    }
    return $s
}

Write-Output 'STEP 1: graceful shutdown issued from INSIDE the guest (no ACPI, no force)'
$s = Get-Sess $n
if (-not $s) { throw 'cannot open session' }
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        & shutdown.exe /s /t 5 /c 'lab policy verification reboot' 2>&1 | ForEach-Object { Write-Output ("  " + $_) }
        Write-Output '  shutdown.exe issued (t+5s)'
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }

$deadline = (Get-Date).AddMinutes(10)
while ((Get-VM -Name $n).State -ne 'Off') {
    if ((Get-Date) -gt $deadline) { throw 'Guest shutdown did not complete within 10 minutes.' }
    Start-Sleep -Seconds 10
}
Write-Output 'PASS  guest shut itself down cleanly (no forced power-off)'

Write-Output ''
Write-Output 'STEP 2: 2 GB static memory while stopped (documented spec)'
Set-VMMemory -VMName $n -StartupBytes (2GB) -DynamicMemoryEnabled $false
$mm = Get-VMMemory -VMName $n
Write-Output ("SET   startup=" + [math]::Round($mm.StartupMemory / 1GB, 2) + "GB dynamic=" + $mm.DynamicMemoryEnabled)

Write-Output ''
Write-Output 'STEP 3: boot and wait'
Start-VM -Name $n
$deadline = (Get-Date).AddMinutes(15)
$up = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 20
    $v = Get-VM -Name $n
    Write-Output ("  state=" + $v.State + " assigned=" + [math]::Round($v.MemoryAssigned / 1GB, 2) + "GB uptime=" + [math]::Round($v.Uptime.TotalMinutes, 1) + "min")
    if ($v.State -eq 'Running' -and $v.Uptime.TotalMinutes -gt 4) { $up = $true; break }
}
if (-not $up) { throw "$n did not boot within 15 minutes." }
Start-Sleep -Seconds 60

Write-Output ''
Write-Output 'STEP 4: PROOF - autologon produced a live, unlocked console session'
$s = Get-Sess $n
if (-not $s) { throw 'no PowerShell Direct session after reboot - check console' }
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        Write-Output ('GuestUptimeMinutes = ' + [math]::Round(((Get-Date) - $boot).TotalMinutes, 1))
        Write-Output ('LastBootUpTime = ' + $boot)
        $q = (& quser.exe 2>&1 | Out-String).Trim()
        Write-Output 'quser:'
        Write-Output $q
        $line = ($q -split "`r?`n" | Where-Object { $_ -match 'console' } | Select-Object -First 1)
        if ($line -and $line -match 'Active') {
            Write-Output 'AUTOLOGONPROOF=PASS console session Active after cold boot'
            if ($line -match '(\d+/\d+/\d+).*?(\d+:\d+:\d+\s*[AP]M)') { Write-Output ("  console logon time: " + $line.Trim()) }
        }
        elseif ($line) { Write-Output ('AUTOLOGONPROOF=FAIL console session state is: ' + $line.Trim()) }
        else { Write-Output 'AUTOLOGONPROOF=FAIL no console session at all' }
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        $w = Get-ItemProperty $k
        Write-Output ("AUTOLOGONCFG user=" + $w.DefaultUserName + " dom=" + $w.DefaultDomainName + " on=" + $w.AutoAdminLogon + " pwdPlaintext=" + ($w.DefaultPassword -is [string]))
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }