# Silent Exchange takeover on BWANA-MAIL-01. No secrets printed.
$ErrorActionPreference = 'Continue'
# Proven live credential: MAIL-01 AutoLogon password (PSDirect succeeded earlier). Do not print it.
[xml]$x = Get-Content 'C:\STEP\BwanaMail\data\BWANA-MAIL-01-Autounattend.xml'
$pwNode = $x.SelectSingleNode("//*[local-name()='AutoLogon']/*[local-name()='Password']/*[local-name()='Value']")
if (-not $pwNode) { throw 'AutoLogon password node missing' }
$pw = $pwNode.InnerText.Trim()
if ($pw.Length -lt 8) { throw 'Password node too short to be the live secret' }
$sec = ConvertTo-SecureString -String $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)

$block = {
    $ErrorActionPreference = 'Continue'
    $out = New-Object System.Collections.Generic.List[string]
    function L([string]$s) { $script:out.Add($s) }

    L '=== HOST ==='
    L ("Computer=" + $env:COMPUTERNAME)
    L ("Domain=" + $env:USERDNSDOMAIN)

    L '=== START STOPPED EXCHANGE SERVICES ==='
    $want = @(
        'MSExchangeTransport','MSExchangeFrontendTransport','MSExchangeDelivery',
        'MSExchangeMailboxReplication','MSExchangeRPC','MSExchangeDiagnostics',
        'MSExchangeTransportLogSearch','MSExchangeEdgeSync','MSExchangeCompliance',
        'MSExchangeHM','MSExchangeHMRecovery','MSExchangeAntispamUpdate','MSExchangeMitigation'
    )
    foreach ($n in $want) {
        $svc = Get-Service -Name $n -ErrorAction SilentlyContinue
        if (-not $svc) { L ("MISSING " + $n); continue }
        if ($svc.Status -ne 'Running') {
            try {
                Set-Service -Name $n -StartupType Automatic -ErrorAction SilentlyContinue
                Start-Service -Name $n -ErrorAction Stop
                L ("STARTED " + $n)
            } catch {
                L ("START-FAIL " + $n + " :: " + $_.Exception.Message)
            }
        } else {
            L ("ALREADY " + $n)
        }
    }

    L '=== SERVICE SNAPSHOT ==='
    Get-Service MSExchange* | ForEach-Object { L ($_.Name + ' ' + $_.Status + ' ' + $_.StartType) }

    L '=== LOAD EXCHANGE SNAPIN ==='
    $snap = Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue
    if (-not $snap) {
        try { Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop; L 'SNAPIN-ADDED' }
        catch { L ('SNAPIN-FAIL ' + $_.Exception.Message) }
    } else { L 'SNAPIN-PRESENT' }

    if (Get-Command Get-ExchangeServer -ErrorAction SilentlyContinue) {
        L '=== EXCHANGE SERVER ==='
        Get-ExchangeServer | ForEach-Object { L ($_.Name + ' edition=' + $_.Edition + ' role=' + $_.ServerRole + ' version=' + $_.AdminDisplayVersion) }
        L '=== ACCEPTED DOMAINS ==='
        Get-AcceptedDomain | ForEach-Object { L ($_.DomainName + ' type=' + $_.DomainType + ' default=' + $_.Default) }
        L '=== EMAIL ADDRESS POLICIES ==='
        Get-EmailAddressPolicy | ForEach-Object { L ($_.Name + ' enabled=' + $_.Enabled + ' priority=' + $_.Priority) }
        L '=== SEND CONNECTORS ==='
        $sc = @(Get-SendConnector)
        if ($sc.Count -eq 0) { L 'NONE' } else { $sc | ForEach-Object { L ($_.Name + ' enabled=' + $_.Enabled + ' fqdn=' + $_.Fqdn + ' addressSpaces=' + ($_.AddressSpaces -join ',')) } }
        L '=== RECEIVE CONNECTORS ==='
        Get-ReceiveConnector | ForEach-Object { L ($_.Identity.ToString() + ' enabled=' + $_.Enabled + ' bindings=' + ($_.Bindings -join ',') + ' fqdn=' + $_.Fqdn) }
        L '=== TRANSPORT RULES ==='
        $tr = @(Get-TransportRule)
        if ($tr.Count -eq 0) { L 'NONE' } else { $tr | ForEach-Object { L ($_.Name + ' state=' + $_.State + ' priority=' + $_.Priority) } }
        L '=== MAILBOXES ==='
        $mb = @(Get-Mailbox -ResultSize Unlimited)
        L ('COUNT=' + $mb.Count)
        $mb | Select-Object -First 40 | ForEach-Object { L ($_.Name + ' smtp=' + $_.PrimarySmtpAddress + ' db=' + $_.Database) }
        L '=== DATABASES ==='
        Get-MailboxDatabase | ForEach-Object { L ($_.Name + ' server=' + $_.Server + ' mounted=' + $_.Mounted + ' edb=' + $_.EdbFilePath) }
        L '=== ORG CONFIG ==='
        $org = Get-OrganizationConfig
        L ('Org=' + $org.Name + ' guid=' + $org.Guid)
    } else {
        L 'NO-EXCHANGE-CMDLETS'
    }
    $out -join "`n"
}

try {
    $text = Invoke-Command -VMName BWANA-MAIL-01 -ScriptBlock $block -Credential $cred -ErrorAction Stop
    $text | Out-File -FilePath 'C:\Users\howar\AppData\Local\Temp\opencode\mail01-exchange-state.txt' -Encoding utf8
    Write-Host 'INSPECT-WRITTEN'
} catch {
    Write-Host ('INSPECT-FAIL ' + $_.Exception.Message)
    exit 1
}
