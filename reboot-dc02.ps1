$ErrorActionPreference = 'Stop'
$n = 'BWANA-DC02'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)

Write-Output ("BEFORE: state=" + (Get-VM -Name $n).State + " assigned=" + [math]::Round((Get-VM -Name $n).MemoryAssigned / 1GB, 2) + "GB")

Write-Output ''
Write-Output 'STEP 1: graceful ACPI shutdown (previously refused because session was locked)'
Stop-VM -Name $n
$deadline = (Get-Date).AddMinutes(6)
while ((Get-VM -Name $n).State -ne 'Off') {
    if ((Get-Date) -gt $deadline) { throw 'Graceful shutdown timed out.' }
    Start-Sleep -Seconds 5
}
Write-Output 'PASS  graceful shutdown succeeded - session is no longer locked'

Write-Output ''
Write-Output 'STEP 2: apply documented 2 GB static memory while stopped'
Set-VMMemory -VMName $n -StartupBytes (2GB) -DynamicMemoryEnabled $false
$s = Get-VMMemory -VMName $n
Write-Output ("SET   startup=" + [math]::Round($s.StartupMemory / 1GB, 2) + "GB dynamic=" + $s.DynamicMemoryEnabled)

Write-Output ''
Write-Output 'STEP 3: start and wait for autologon'
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
Write-Output ('PASS  VM back up with ' + [math]::Round((Get-VM -Name $n).MemoryAssigned / 1GB, 2) + 'GB')

Write-Output ''
Write-Output 'STEP 4: prove an interactive autologon session exists (not stranded at logon)'
$sess = $null
for ($i = 1; $i -le 8 -and -not $sess; $i++) {
    try { $sess = New-PSSession -VMName $n -Credential $cred -ErrorAction Stop }
    catch { Write-Output "  psdirect attempt $i failed"; Start-Sleep -Seconds 20 }
}
if (-not $sess) { throw 'No PowerShell Direct session after reboot.' }
try {
    Invoke-Command -Session $sess -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        Write-Output ('UptimeSeconds = ' + [math]::Round((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime, 0))
        Write-Output '--- quser (interactive sessions) ---'
        $q = (& quser.exe 2>&1 | Out-String)
        Write-Output ($q.Trim())
        Write-Output '--- console session present? ---'
        if ($q -match '(?im)^\S+\s+console') { Write-Output 'AUTOLOGONPROOF=console-session-present' }
        else { Write-Output 'AUTOLOGONPROOF=NO-console-session' }
    }
}
finally { Remove-PSSession $sess -ErrorAction SilentlyContinue }