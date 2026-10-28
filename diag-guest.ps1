$ErrorActionPreference = 'Continue'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
$plain = $cred.GetNetworkCredential().Password

$hostHash = (Get-FileHash 'C:\STEP\BwanaAD\scripts\set-lab-desktop.ps1' -Algorithm SHA256).Hash
Write-Output ("HOST script SHA256 = " + $hostHash)

$s = New-PSSession -VMName BWANA-DC02 -Credential $cred -ErrorAction Stop
try {
    Write-Output '--- guest file hashes / state ---'
    Invoke-Command -Session $s -ScriptBlock {
        $g = "$env:SystemRoot\Temp\set-lab-desktop.ps1"
        Write-Output ("GUEST script exists=" + (Test-Path $g))
        if (Test-Path $g) { Write-Output ("GUEST script SHA256 = " + (Get-FileHash $g -Algorithm SHA256).Hash) }
        Write-Output ("GUEST script length = " + $(if (Test-Path $g) { (Get-Item $g).Length } else { 0 }))
        $p = Get-Process -Name 'Autologon64' -ErrorAction SilentlyContinue
        Write-Output ("GUEST stale Autologon64 processes = " + @($p).Count)
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
        $w = Get-ItemProperty $k
        Write-Output ("GUEST AutoAdminLogon=" + $w.AutoAdminLogon + " user=" + $w.DefaultUserName + " dom=" + $w.DefaultDomainName)
        $dp = (Get-ItemProperty $k -Name DefaultPassword -ErrorAction SilentlyContinue).DefaultPassword
        Write-Output ("GUEST DefaultPassword type = " + $(if ($null -eq $dp) { 'absent' } elseif ($dp -is [byte[]]) { 'byte[]/LSA' } else { 'PLAINTEXT' }))
    }

    Write-Output ''
    Write-Output '--- invoke guest script directly, full stream capture ---'
    $guest = "$env:SystemRoot\Temp\set-lab-desktop.ps1"
    Invoke-Command -Session $s -ScriptBlock {
        param($g, $p)
        $ErrorActionPreference = 'Continue'
        $o = & $g -UserName 'Administrator' -Domain 'BWANA' -Password $p -ErrorAction Continue 2>&1
        Write-Output '---STDOUT---'
        $o | ForEach-Object { Write-Output ("[" + $_ + "]") }
    } -ArgumentList @($guest, $plain)
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }