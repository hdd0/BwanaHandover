$ErrorActionPreference = 'Stop'
[xml]$x = Get-Content 'C:\STEP\BwanaMail\data\BWANA-MAIL-01-Autounattend.xml'
$pw = $x.SelectSingleNode("//*[local-name()='AutoLogon']/*[local-name()='Password']/*[local-name()='Value']").InnerText.Trim()
$sec = ConvertTo-SecureString -String $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)

$block = {
    $ErrorActionPreference = 'Continue'
    $log = New-Object System.Collections.Generic.List[string]
    function L([string]$s) { $script:log.Add($s) }
    if (-not (Get-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue)) {
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
    }

    L '=== ACCEPTED ==='
    Get-AcceptedDomain | ForEach-Object { L ($_.DomainName.ToString() + ' type=' + $_.DomainType + ' default=' + $_.Default) }

    L '=== EAP BEFORE ==='
    $pol = Get-EmailAddressPolicy -Identity 'Default Policy'
    $current = @($pol.EnabledEmailAddressTemplates | ForEach-Object { $_.ToString() })
    $current | ForEach-Object { L ("TPL " + $_) }

    # Exactly one primary SMTP. Primary = bwanakhasu.one. Others secondary.
    $secondary = New-Object System.Collections.Generic.List[string]
    foreach ($t in $current) {
        $addr = $t
        if ($addr -match '^[Ss][Mm][Tt][Pp]:(.+)$') { $addr = $Matches[1] }
        if ($addr -like '*@bwanakhasu.one') { continue }
        if ($secondary -notcontains ('smtp:' + $addr)) { $secondary.Add('smtp:' + $addr) }
    }
    foreach ($extra in @('smtp:%m@bwanakhasu.co.za','smtp:%m@bwanakhasu.com')) {
        $dom = ($extra -split '@')[1]
        if (-not ($secondary | Where-Object { $_ -like ('*@' + $dom) })) { $secondary.Add($extra) }
    }
    $newTpl = @('SMTP:%m@bwanakhasu.one') + @($secondary)
    L ('EAP-PLAN ' + ($newTpl -join ' | '))
    try {
        Set-EmailAddressPolicy -Identity 'Default Policy' -EnabledEmailAddressTemplates $newTpl -ErrorAction Stop
        Update-EmailAddressPolicy -Identity 'Default Policy' -ErrorAction SilentlyContinue
        L 'EAP-UPDATED'
    } catch {
        L ('EAP-FAIL ' + $_.Exception.Message)
    }

    $srv = (Get-ExchangeServer | Select-Object -First 1).Name
    if (-not (Get-SendConnector -Identity 'BWANA-Internet' -ErrorAction SilentlyContinue)) {
        New-SendConnector -Name 'BWANA-Internet' -AddressSpaces 'SMTP:*;1' -DNSRoutingEnabled $true -SourceTransportServers $srv -Fqdn 'mail.bwanakhasu.co.za' -Enabled $true | Out-Null
        L 'SEND-CREATED'
    } else {
        Set-SendConnector -Identity 'BWANA-Internet' -Enabled $true -DNSRoutingEnabled $true -Fqdn 'mail.bwanakhasu.co.za' -SourceTransportServers $srv
        L 'SEND-UPDATED'
    }
    Get-SendConnector | ForEach-Object { L ('SEND ' + $_.Name + ' enabled=' + $_.Enabled + ' fqdn=' + $_.Fqdn + ' spaces=' + ($_.AddressSpaces -join ',')) }

    Get-ReceiveConnector | ForEach-Object {
        L ('RCV ' + $_.Name + ' enabled=' + $_.Enabled + ' bind=' + ($_.Bindings -join ',') + ' groups=' + $_.PermissionGroups)
        if ($_.Bindings -match ':25' -and ($_.PermissionGroups.ToString() -notmatch 'Anonymous')) {
            try {
                Set-ReceiveConnector -Identity $_.Identity -PermissionGroups AnonymousUsers,ExchangeServers,ExchangeUsers,ExchangeLegacyServers
                L ('RCV-ANON ' + $_.Name)
            } catch { L ('RCV-ANON-FAIL ' + $_.Name + ' ' + $_.Exception.Message) }
        }
    }

    $archive = Get-Mailbox -Identity 'bwana-archive' -ErrorAction SilentlyContinue
    if (-not $archive) {
        try {
            $sp = ConvertTo-SecureString -String $using:pw -AsPlainText -Force
            New-Mailbox -Name 'bwana-archive' -Alias 'bwana-archive' -UserPrincipalName 'bwana-archive@ad.bwanakhasu.one' -Password $sp -ResetPasswordOnNextLogon $false | Out-Null
            L 'ARCHIVE-CREATED'
        } catch { L ('ARCHIVE-FAIL ' + $_.Exception.Message) }
    } else { L 'ARCHIVE-EXISTS' }

    foreach ($rule in @(
        @{ N='BWANA-Copy-Outbound-To-Archive'; From='InOrganization'; To='NotInOrganization' },
        @{ N='BWANA-Copy-Inbound-To-Archive'; From='NotInOrganization'; To='InOrganization' }
    )) {
        if (-not (Get-TransportRule -Identity $rule.N -ErrorAction SilentlyContinue)) {
            if (Get-Mailbox -Identity 'bwana-archive' -ErrorAction SilentlyContinue) {
                try {
                    New-TransportRule -Name $rule.N -Enabled $true -FromScope $rule.From -SentToScope $rule.To -BlindCopyTo 'bwana-archive@ad.bwanakhasu.one' -Comments 'Archive copy only. Original message is delivered.' | Out-Null
                    L ('RULE-CREATED ' + $rule.N)
                } catch { L ('RULE-FAIL ' + $rule.N + ' ' + $_.Exception.Message) }
            }
        } else { L ('RULE-EXISTS ' + $rule.N) }
    }

    L '=== MAILBOXES ==='
    @(Get-Mailbox -ResultSize Unlimited) | ForEach-Object { L ('MBX ' + $_.Name + ' ' + $_.PrimarySmtpAddress) }

    try {
        $tf = Test-Mailflow -ErrorAction Stop
        L ('TEST-MAILFLOW ' + $tf.TestMailflowResult)
    } catch { L ('TEST-MAILFLOW-FAIL ' + $_.Exception.Message) }

    # Firewall for SMTP/HTTPS from the host LAN
    foreach ($port in 25,587,443,80) {
        $name = "BWANA-Mail-$port"
        if (-not (Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName $name -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -Profile Any | Out-Null
            L ("FW-ADDED $port")
        } else { L ("FW-EXISTS $port") }
    }

    $log -join "`n"
}
$text = Invoke-Command -VMName BWANA-MAIL-01 -Credential $cred -ScriptBlock $block
$text | Out-File 'C:\Users\howar\AppData\Local\Temp\opencode\mail01-configure-result.txt' -Encoding utf8
Write-Host $text
