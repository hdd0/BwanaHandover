$ErrorActionPreference = 'Stop'
$n = 'BWANA-DC02'
$os = Get-CimInstance Win32_OperatingSystem
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
Write-Output ("Host free RAM = " + $freeGB + " GB")

$targetGB = 1.5
if ($freeGB -lt ($targetGB + 0.75)) { throw "Not enough headroom: free=$freeGB GB, target=$targetGB GB" }

Set-VMMemory -VMName $n -StartupBytes ([int64]($targetGB * 1GB)) -DynamicMemoryEnabled $false
Start-VM -Name $n
Write-Output 'Start issued.'

$deadline = (Get-Date).AddMinutes(15)
$up = $false
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 20
    $v = Get-VM -Name $n
    Write-Output ("  state=" + $v.State + " assigned=" + [math]::Round($v.MemoryAssigned / 1GB, 2) + "GB uptime=" + [math]::Round($v.Uptime.TotalMinutes, 1) + "min")
    if ($v.State -eq 'Running' -and $v.Uptime.TotalMinutes -gt 3) { $up = $true; break }
}
if (-not $up) { throw "$n did not start/boot within 15 minutes." }
Write-Output ('PASS  ' + $n + ' running with ' + [math]::Round((Get-VM -Name $n).MemoryAssigned / 1GB, 2) + ' GB')

Write-Output ''
Write-Output 'Waiting for autologon session, then proving it'
Start-Sleep -Seconds 60
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
$s = $null
for ($i = 1; $i -le 8 -and -not $s; $i++) {
    try { $s = New-PSSession -VMName $n -Credential $cred -ErrorAction Stop }
    catch { Write-Output "  psdirect attempt $i failed"; Start-Sleep -Seconds 20 }
}
if ($s) {
    try {
        Invoke-Command -Session $s -ScriptBlock {
            $ErrorActionPreference = 'Continue'
            $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            Write-Output ('GuestUptimeMinutes = ' + [math]::Round(((Get-Date) - $boot).TotalMinutes, 1))
            Write-Output ('LastBootUpTime     = ' + $boot)
            $q = (& quser.exe 2>&1 | Out-String).Trim()
            Write-Output 'quser:'
            Write-Output $q
            $line = ($q -split "`r?`n" | Where-Object { $_ -match 'console' } | Select-Object -First 1)
            if ($line -and $line -match 'Active') { Write-Output 'AUTOLOGONPROOF=PASS console session Active after cold boot' }
            elseif ($line) { Write-Output ('AUTOLOGONPROOF=FAIL console state: ' + $line.Trim()) }
            else { Write-Output 'AUTOLOGONPROOF=FAIL no console session' }
        }
    }
    finally { Remove-PSSession $s -ErrorAction SilentlyContinue }
}