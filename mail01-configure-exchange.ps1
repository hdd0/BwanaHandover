# Configure BWANA-MAIL-01 Exchange for send/receive. No secrets printed.
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
        Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction Stop
    }
    L 'SNAPIN-OK'

    $srv = @(Get-ExchangeServer)[0]
    L ("SERVER=" + $srv.Name + " VERSION=" + $srv.AdminDisplayVersion + " ROLE=" + $srv.ServerRole)

    $wanted = @('bwanakhasu.one','bwanakhasu.co.za','bwanakhasu.com')
    foreach ($d in $wanted) {
        $ad = Get-AcceptedDomain -Identity $d -ErrorAction SilentlyContinue
        if (-not $ad) {
            New-AcceptedDomain -Name $d -DomainName $d -DomainType Authoritative | Out-Null
            L ("ACCEPTED-CREATED " + $d)
        } else {
            if ($ad.DomainType -ne 'Authoritative') {
                Set-AcceptedDomain -Identity $d -DomainType Authoritative
                L ("ACCEPTED-SET-AUTHORITATIVE " + $d)
            } else {
                L ("ACCEPTED-EXISTS " + $d)
            }
        }
    }
    # Primary accepted domain is bwanakhasu.one (BWANA-MAIL-01 is the mail org).
    Set-AcceptedDomain -Identity 'bwanakhasu.one' -MakeDefault $true
    L 'DEFAULT-DOMAIN=bwanakhasu.one'

    $pol = Get-EmailAddressPolicy -Identity 'Default Policy' -ErrorAction SilentlyContinue
    if ($pol) {
        # Keep existing templates and add the three public domains if missing.
        $templates = @($pol.EnabledEmailAddressTemplates | ForEach-Object { $_.ToString() })
        $need = @(
            'SMTP:%m@bwanakhasu.one',
            'smtp:%m@bwanakhasu.co.za',
            'smtp:%m@bwanakhasu.com'
        )
        $changed = $false
        foreach ($n in $need) {
            $prefix = ($n -split '@')[1]
            if (-not ($templates | Where-Object { $_ -like ('*@' + $prefix) })) {
                $templates += $n
                $changed = $true
            }
        }
        # Ensure one primary SMTP for .one
        if (-not ($templates | Where-Object { $_ -like 'SMTP:%m@bwanakhasu.one' })) {
            $templates = @('SMTP:%m@bwanakhasu.one') + ($templates | Where-Object { $_ -notlike '*@bwanakhasu.one' })
            $changed = $true
        }
        if ($changed) {
            Set-EmailAddressPolicy -Identity 'Default Policy' -EnabledEmailAddressTemplates $templates
            Update-EmailAddressPolicy -Identity 'Default Policy' -ErrorAction SilentlyContinue
            L 'EAP-UPDATED'
        } else {
            L 'EAP-ALREADY'
        }
        L ('EAP=' + ($templates -join ' | '))
    }

    $sc = Get-SendConnector -Identity 'BWANA-Internet' -ErrorAction SilentlyContinue
    if (-not $sc) {
        New-SendConnector -Name 'BWANA-Internet' -AddressSpaces 'SMTP:*;1' -DNSRoutingEnabled $true -SourceTransportServers $srv.Name -Fqdn 'mail.bwanakhasu.co.za' -Enabled $true | Out-Null
        L 'SEND-CONNECTOR-CREATED BWANA-Internet'
    } else {
        Set-SendConnector -Identity 'BWANA-Internet' -Enabled $true -DNSRoutingEnabled $true -Fqdn 'mail.bwanakhasu.co.za'
        L 'SEND-CONNECTOR-EXISTS'
    }

    Get-ReceiveConnector | ForEach-Object {
        L ("RCV " + $_.Identity + " enabled=" + $_.Enabled + " bind=" + ($_.Bindings -join ',') + " groups=" + ($_.PermissionGroups -join ','))
    }
    $front = Get-ReceiveConnector | Where-Object { $_.Name -like '*Frontend*' -or $_.Name -like '*Default*' }
    foreach ($rc in $front) {
        $groups = @($rc.PermissionGroups.ToString() -split ',')
        if ($rc.Bindings -match ':25' -and $groups -notcontains 'AnonymousUsers') {
            Set-ReceiveConnector -Identity $rc.Identity -PermissionGroups ($rc.PermissionGroups.ToString() + ',AnonymousUsers')
            L ("RCV-ANON-ADDED " + $rc.Identity)
        }
    }

    # Operational transport rules. Copy, do not redirect — redirect would break receive.
    $archive = Get-Mailbox -Identity 'bwana-archive' -ErrorAction SilentlyContinue
    if (-not $archive) {
        $pwd = ConvertTo-SecureString -String $using:pw -AsPlainText -Force
        try {
            New-Mailbox -Name 'bwana-archive' -Alias 'bwana-archive' -UserPrincipalName 'bwana-archive@ad.bwanakhasu.one' -Password $pwd -ResetPasswordOnNextLogon $false | Out-Null
            L 'ARCHIVE-MAILBOX-CREATED bwana-archive'
        } catch {
            L ("ARCHIVE-MAILBOX-FAIL " + $_.Exception.Message)
        }
    } else {
        L 'ARCHIVE-MAILBOX-EXISTS'
    }
    if (-not (Get-TransportRule -Identity 'BWANA-Copy-To-Archive' -ErrorAction SilentlyContinue)) {
        if (Get-Mailbox -Identity 'bwana-archive' -ErrorAction SilentlyContinue) {
            New-TransportRule -Name 'BWANA-Copy-To-Archive' -Enabled $true -FromScope InOrganization -SentToScope NotInOrganization -BlindCopyTo 'bwana-archive@ad.bwanakhasu.one' -Comments 'Copy outbound mail to the archive mailbox. Does not redirect or drop the original.' | Out-Null
            L 'RULE-CREATED BWANA-Copy-To-Archive'
        }
    } else { L 'RULE-EXISTS BWANA-Copy-To-Archive' }
    if (-not (Get-TransportRule -Identity 'BWANA-Copy-Inbound-To-Archive' -ErrorAction SilentlyContinue)) {
        if (Get-Mailbox -Identity 'bwana-archive' -ErrorAction SilentlyContinue) {
            New-TransportRule -Name 'BWANA-Copy-Inbound-To-Archive' -Enabled $true -FromScope NotInOrganization -SentToScope InOrganization -BlindCopyTo 'bwana-archive@ad.bwanakhasu.one' -Comments 'Copy inbound mail to the archive mailbox. Does not redirect or drop the original.' | Out-Null
            L 'RULE-CREATED BWANA-Copy-Inbound-To-Archive'
        }
    } else { L 'RULE-EXISTS BWANA-Copy-Inbound-To-Archive' }

    $mbx = @(Get-Mailbox -ResultSize Unlimited)
    L ("MAILBOX-COUNT=" + $mbx.Count)
    $mbx | Select-Object -First 50 | ForEach-Object { L ("MBX " + $_.Name + " " + $_.PrimarySmtpAddress) }

    L '=== URLS ==='
    Get-OwaVirtualDirectory | ForEach-Object { L ("OWA internal=" + $_.InternalUrl + " external=" + $_.ExternalUrl) }
    Get-EcpVirtualDirectory | ForEach-Object { L ("ECP internal=" + $_.InternalUrl + " external=" + $_.ExternalUrl) }

    try {
        $tf = Test-Mailflow -ErrorAction Stop
        L ("TEST-MAILFLOW " + $tf.TestMailflowResult + " latency=" + $tf.MessageLatencyTime)
    } catch {
        L ("TEST-MAILFLOW-FAIL " + $_.Exception.Message)
    }

    $log -join "`n"
}

$text = Invoke-Command -VMName BWANA-MAIL-01 -Credential $cred -ScriptBlock $block
$text | Out-File 'C:\Users\howar\AppData\Local\Temp\opencode\mail01-configure-result.txt' -Encoding utf8
Write-Host $text
