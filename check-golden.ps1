$ErrorActionPreference = 'Continue'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$vm = 'BWANA-GOLDEN-SRC'
$s = $null
for ($i = 1; $i -le 4 -and -not $s; $i++) {
    try { $s = New-PSSession -VMName $vm -Credential $cred -ErrorAction Stop }
    catch { Start-Sleep -Seconds 15 }
}
if ($s) {
    try {
        Invoke-Command -Session $s -ScriptBlock {
            $ErrorActionPreference = 'Continue'
            Write-Output ('Computer: ' + $env:COMPUTERNAME)
            $os = Get-CimInstance Win32_OperatingSystem
            Write-Output ('OS: ' + $os.Caption + ' build ' + $os.BuildNumber)
            Write-Output ('LastBootUpTime: ' + $os.LastBootUpTime)
            Write-Output ('UptimeMin: ' + [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalMinutes, 1))
            $q = (& quser.exe 2>&1 | Out-String).Trim()
            Write-Output 'quser:'
            Write-Output $q
        }
    }
    finally { Remove-PSSession $s -ErrorAction SilentlyContinue }
}
else { Write-Output 'No PowerShell Direct session - VM may not have Windows ready' }