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

Write-Output 'STEP 1: clear the stale LOCKED console session from inside the guest'
$s = Get-Sess $n
if (-not $s) { throw 'cannot open session' }
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        $q = (& quser.exe 2>&1 | Out-String)
        Write-Output 'BEFORE quser:'
        Write-Output $q.Trim()
        $ids = @()
        foreach ($line in ($q -split "`r?`n")) {
            if ($line -match '^\s*>(\d+)\s+(\S+)\s+console') { $ids += [int]$Matches[1] }
            elseif ($line -match '^\s*(\d+)\s+(\S+)\s+console') { $ids += [int]$Matches[1] }
        }
        Write-Output ('consoleSessionIds=' + ($ids -join ','))
        foreach ($id in $ids) {
            Write-Output ("  logoff session $id ...")
            & logoff.exe $id 2>&1 | ForEach-Object { Write-Output ("    " + $_) }
        }
        Start-Sleep -Seconds 8
        $q2 = (& quser.exe 2>&1 | Out-String)
        Write-Output 'AFTER quser:'
        Write-Output $q2.Trim()
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }

Write-Output ''
Write-Output 'STEP 2: graceful ACPI shutdown should now succeed'
Stop-VM -Name $n
$deadline = (Get-Date).AddMinutes(6)
while ((Get-VM -Name $n).State -ne 'Off') {
    if ((Get-Date) -gt $deadline) { throw 'Graceful shutdown timed out.' }
    Start-Sleep -Seconds 5
}
Write-Output 'PASS  graceful shutdown succeeded (machine no longer locked)'

Write-Output ''
Write-Output 'STEP 3: 2 GB static memory while stopped'
Set-VMMemory -VMName $n -StartupBytes (2GB) -DynamicMemoryEnabled $false
$mm = Get-VMMemory -VMName $n
Write-Output ("SET   startup=" + [math]::Round($mm.StartupMemory / 1GB, 2) + "GB dynamic=" + $mm.DynamicMemoryEnabled)

Write-Output ''
Write-Output 'STEP 4: boot and prove autologon created an unlocked console session'
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

Start-Sleep -Seconds 45
$s = Get-Sess $n
if (-not $s) { throw 'no PowerShell Direct session after reboot' }
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        Write-Output ('GuestUptimeMinutes = ' + [math]::Round(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes, 1))
        $q = (& quser.exe 2>&1 | Out-String)
        Write-Output 'quser after reboot:'
        Write-Output $q.Trim()
        if ($q -match '(?im)\sconsole\s') { Write-Output 'AUTOLOGONPROOF=PASS console-session-present' }
        else { Write-Output 'AUTOLOGONPROOF=FAIL no-console-session' }
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }