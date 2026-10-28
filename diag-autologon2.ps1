$ErrorActionPreference = 'Continue'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator', $sec)
$plain = $cred.GetNetworkCredential().Password
$target = 'BWANA-DC02'

$s = New-PSSession -VMName $target -Credential $cred -ErrorAction Stop
try {
    Invoke-Command -Session $s -ScriptBlock {
        param($p)
        $exe = "$env:SystemRoot\Temp\Autologon64.exe"
        $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'

        # accept EULA so we see past the licence banner
        $eula = 'HKCU:\Software\Sysinternals\Autologon'
        New-Item -Path $eula -Force | Out-Null
        Set-ItemProperty $eula -Name EulaAccepted -Value 1 -Type DWord -Force

        function Show-State($label) {
            $v = Get-ItemProperty $k
            $pt = if ($v.DefaultPassword -is [byte[]]) { 'LSA' } elseif ($v.DefaultPassword) { 'PLAINTEXT' } else { 'absent' }
            Write-Output ("    -> state: AutoAdminLogon=" + $v.AutoAdminLogon + " user=" + $v.DefaultUserName + " dom=" + $v.DefaultDomainName + " pwd=" + $pt)
        }

        function Try-Args($label, $argList) {
            $out = & $exe @argList 2>&1 | Out-String
            $code = $LASTEXITCODE
            $short = ($out -replace '\s+', ' ').Trim()
            if ($short.Length -gt 120) { $short = $short.Substring(0, 120) + '...' }
            Write-Output ("  [" + $label + "] exit=" + $code + " out='" + $short + "'")
            Show-State $label
        }

        Write-Output '--- baseline ---'
        Show-State 'baseline'

        Write-Output ''
        Write-Output '--- password charset ---'
        $sp = ($p.ToCharArray() | Where-Object { '@#$%^&*-_=+?!'.Contains($_) })
        Write-Output ('special chars present: ' + $sp.Count + '  firstCharCode=' + [int][char]$p[0] + '  containsQuote=' + ($p.Contains('"')) + ' containsSpace=' + ($p.Contains(' ')))

        Write-Output ''
        Write-Output '--- matrix ---'
        Try-Args 'user dom realpass' @('Administrator', 'BWANA', $p)
        Try-Args 'dom user realpass' @('BWANA', 'Administrator', $p)
        Try-Args 'user . realpass' @('Administrator', '.', $p)
        Try-Args 'user dom simplepass' @('Administrator', 'BWANA', 'Test1234!')
        Try-Args 'user dom blankpass' @('Administrator', 'BWANA', '')
    } -ArgumentList $plain
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }