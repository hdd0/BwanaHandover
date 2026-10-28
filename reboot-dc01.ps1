$ErrorActionPreference = 'Stop'
$n = 'BWANA-DC01'
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

Write-Output 'STEP 1: graceful shutdown from inside the guest'
$s = Get-Sess $n
if (-not $s) { throw 'cannot open session on ' + $n }
try {
    Invoke-Command -Session $s -ScriptBlock {
        & shutdown.exe /s /t 5 /c 'lab policy verification reboot' 2>&1 | Out-Null
        Write-Output '  shutdown.exe issued'
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }

$deadline = (Get-Date).AddMinutes(10)
while ((Get-VM -Name $n).State -ne 'Off') {
    if ((Get-Date) -gt $deadline) { throw 'shutdown did not complete in 10 minutes' }
    Start-Sleep -Seconds 10
}
Write-Output 'PASS  clean shutdown'

Write-Output ''
Write-Output 'STEP 2: 1.5 GB static while stopped'
Set-VMMemory -VMName $n -StartupBytes ([int64](1.5GB)) -DynamicMemoryEnabled $false
Write-Output 'SET   1.5 GB static'

Write-Output ''
Write-Output 'STEP 3: boot'
Start-VM -Name $n
$deadline = (Get-Date).AddMinutes(15)
$up = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 20
    $v = Get-VM -Name $n
    Write-Output ("  state=" + $v.State + " assigned=" + [math]::Round($v.MemoryAssigned / 1GB, 2) + "GB uptime=" + [math]::Round($v.Uptime.TotalMinutes, 1) + "min")
    if ($v.State -eq 'Running' -and $v.Uptime.TotalMinutes -gt 3) { $up = $true; break }
}
if (-not $up) { throw "$n did not boot in 15 minutes" }
Write-Output ('PASS  running, ' + [math]::Round((Get-VM -Name $n).MemoryAssigned / 1GB, 2) + ' GB')

Write-Output ''
Write-Output 'STEP 4: autologon proof'
Start-Sleep -Seconds 60
$s = Get-Sess $n
if (-not $s) { throw 'no session after reboot' }
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        Write-Output ('LastBootUpTime     = ' + $boot)
        Write-Output ('GuestUptimeMinutes = ' + [math]::Round(((Get-Date) - $boot).TotalMinutes, 1))
        $q = (& quser.exe 2>&1 | Out-String).Trim()
        Write-Output 'quser:'
        Write-Output $q
        $line = ($q -split "`r?`n" | Where-Object { $_ -match 'console' } | Select-Object -First 1)
        if ($line -and $line -match 'Active') { Write-Output 'AUTOLOGONPROOF=PASS console session Active after cold boot' }
        elseif ($line) { Write-Output ('AUTOLOGONPROOF=FAIL console state: ' + $line.Trim()) }
        else { Write-Output 'AUTOLOGONPROOF=FAIL no console session' }
        $w = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        Write-Output ("AUTOLOGONCFG user=" + $w.DefaultUserName + " dom=" + $w.DefaultDomainName + " on=" + $w.AutoAdminLogon + " pwdPlaintext=" + ($w.DefaultPassword -is [string]))
        Write-Output ('DNS = ' + ((Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | Select-Object -First 1).ServerAddresses -join ','))
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }