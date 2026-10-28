$ErrorActionPreference = 'Continue'
$name = 'BWANA-GOLDEN-SRC'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)

Write-Output "Waiting for unattended Setup to finish on $name ..."
$deadline = (Get-Date).AddMinutes(45)
$ready = $false
$lastDisk = 0
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 60
    $v = Get-VM -Name $name -ErrorAction SilentlyContinue
    if (-not $v) { Write-Output '  VM disappeared!'; break }
    $disk = (Get-Item $v.Paths.VHD -ErrorAction SilentlyContinue).Length
    $gb = [math]::Round($disk / 1GB, 2)
    Write-Output ("  state=" + $v.State + " uptime=" + [math]::Round($v.Uptime.TotalMinutes, 1) + "min osDiskGB=" + $gb)
    $lastDisk = $gb
    try {
        $s = New-PSSession -VMName $name -Credential $cred -ErrorAction Stop
        $probe = Invoke-Command -Session $s -ScriptBlock {
            $ErrorActionPreference = 'Continue'
            [pscustomobject]@{
                Computer = $env:COMPUTERNAME
                Caption  = (Get-CimInstance Win32_OperatingSystem).Caption
                Version  = (Get-CimInstance Win32_OperatingSystem).Version
                Build    = (Get-CimInstance Win32_OperatingSystem).BuildNumber
                UpMinutes = [math]::Round(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes, 1)
            }
        }
        Remove-PSSession $s -ErrorAction SilentlyContinue
        Write-Output ('  >>> Windows is responding: ' + $probe.Caption + ' build ' + $probe.Build + ' (guest uptime ' + $probe.UpMinutes + ' min)')
        $ready = $true
        break
    }
    catch { }
}
if (-not $ready) {
    Write-Output ("RESULT: not ready within 45 minutes (last osDiskGB=" + $lastDisk + ')')
    exit 1
}
Write-Output 'RESULT: golden build is up'