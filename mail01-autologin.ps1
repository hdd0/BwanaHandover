<#
  Apply autologin to BWANA-MAIL-01 using the Unattend password.
  Password value is extracted in-memory, passed to the VM, never printed.
#>
$ErrorActionPreference = 'Stop'
$unattend = 'C:\STEP\BwanaMail\data\BWANA-MAIL-01-Autounattend.xml'
[xml]$x = Get-Content $unattend

# Find the password node anywhere in the document (AdministratorPassword or Password>Value)
$node = $x.SelectSingleNode("//*[local-name()='Password']/*[local-name()='Value']")
if (-not $node) { $node = $x.SelectSingleNode("//*[local-name()='AdministratorPassword']/*[local-name()='Value']") }
if (-not $node) { $node = $x.SelectSingleNode("//*[contains(local-name(),'Password')]/*[local-name()='Value']") }
if (-not $node) { throw 'No password node found in Unattend' }
$pw = $node.InnerText.Trim()
Write-Host ("Password located: {0} chars (REDACTED)" -f $pw.Length)

# Identify which local accounts exist in the Unattend (to match the admin account name)
$acct = $x.SelectSingleNode("//*[local-name()='UserAccounts']//*[local-name()='Name']")
Write-Host ("Unattend account name: {0}" -f $(if ($acct) { $acct.InnerText } else { '(not found)' }))

# --- Apply to BWANA-MAIL-01 via PowerShell Direct ---
# Try credential forms in order: UPN, then local\Administrator (per known gotcha: try both)
$userForms = @('Administrator@ad.bwanakhasu.one', 'BWANA\Administrator', 'Administrator')
$remote = {
    param([string]$P, [string]$U, [string]$D)
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
    Set-ItemProperty -Path $key -Name 'AutoAdminLogon'  -Value '1' -Type String -Force
    Set-ItemProperty -Path $key -Name 'DefaultUserName' -Value $U -Type String -Force
    Set-ItemProperty -Path $key -Name 'DefaultPassword' -Value $P -Type String -Force
    Set-ItemProperty -Path $key -Name 'DefaultDomainName' -Value $D -Type String -Force
    Remove-ItemProperty -Path $key -Name 'AutoLogonCount' -ErrorAction SilentlyContinue
    # Confirm (do not print the password)
    $v = Get-ItemProperty -Path $key
    [pscustomobject]@{
        AutoAdminLogon  = $v.AutoAdminLogon
        DefaultUserName = $v.DefaultUserName
        DefaultDomain   = $v.DefaultDomainName
        PasswordSet     = [bool]($v.DefaultPassword -and $v.DefaultPassword.Length -gt 0)
        Computer        = $env:COMPUTERNAME
    }
}

$ok = $false
foreach ($uf in $userForms) {
    try {
        $sec = ConvertTo-SecureString -String $pw -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($uf, $sec)
        $res = Invoke-Command -VMName BWANA-MAIL-01 -ScriptBlock $remote -ArgumentList $pw, 'BWANA\Administrator', 'BWANA.KHASU.ONE' -Credential $cred -ErrorAction Stop
        Write-Host ("AUTOLOGIN OK via credential form '{0}'" -f $uf)
        $res | Format-List | Out-String | Write-Host
        $ok = $true
        break
    } catch {
        Write-Host ("Credential form '{0}' failed: {1}" -f $uf, $_.Exception.Message)
    }
}
if (-not $ok) { Write-Host 'RESULT: FAILED to apply autologin via PowerShell Direct'; exit 1 }
Write-Host 'RESULT: PASS - autologin configured on BWANA-MAIL-01 (password REDACTED)'
