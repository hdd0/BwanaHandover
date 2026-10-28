$ErrorActionPreference = 'Continue'
$secFile = 'C:\STEP\unattend\secrets\admin.dpapi.txt'
$sec = ConvertTo-SecureString ((Get-Content $secFile -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$plain = $cred.GetNetworkCredential().Password

$s = New-PSSession -VMName BWANA-DC01 -Credential $cred -ErrorAction Stop
try {
    Invoke-Command -Session $s -ScriptBlock {
        param($p)
        $exe = "$env:SystemRoot\Temp\Autologon64.exe"
        if (-not (Test-Path $exe)) { throw 'exe not staged' }

        Write-Output ('--- length / charset profile (no value) ---')
        Write-Output ('len=' + $p.Length)
        $hasSpecial = ($p.ToCharArray() | Where-Object { '@#$%^&*-_=+?!'.Contains($_) }).Count
        Write-Output ('specialChars=' + $hasSpecial)
        Write-Output ('firstChar=' + [int][char]$p[0])
        Write-Output ('startsWithDash=' + ($p[0] -eq '-'))

        Write-Output ''
        Write-Output '--- autologon /? ---'
        $u = & $exe '/?' 2>&1 | Out-String
        Write-Output $u.Trim()

        Write-Output ''
        Write-Output '--- attempt A: user domain password (local domain) ---'
        $outA = & $exe 'Administrator' $env:COMPUTERNAME $p 2>&1 | Out-String
        Write-Output ('exit=' + $LASTEXITCODE)
        Write-Output $outA.Trim()

        Write-Output ''
        Write-Output '--- attempt B: user . password ---'
        $outB = & $exe 'Administrator' '.' $p 2>&1 | Out-String
        Write-Output ('exit=' + $LASTEXITCODE)
        Write-Output $outB.Trim()

        Write-Output ''
        Write-Output '--- attempt C: simple test password ---'
        $outC = & $exe 'Administrator' $env:COMPUTERNAME 'Test1234!' 2>&1 | Out-String
        Write-Output ('exit=' + $LASTEXITCODE)
        Write-Output $outC.Trim()

        Write-Output ''
        Write-Output '--- current Winlogon state ---'
        Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' |
            Select-Object AutoAdminLogon, DefaultUserName, DefaultDomainName,
                @{n = 'PasswordType'; e = { if ($_.DefaultPassword -is [byte[]]) { 'LSA-byte[]' } elseif ($_.DefaultPassword) { 'PLAINTEXT' } else { 'absent' } } } |
            Format-List | Out-String | Write-Output
    } -ArgumentList $plain
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }