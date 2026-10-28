$ErrorActionPreference = 'Stop'
[xml]$x = Get-Content 'C:\STEP\BwanaMail\data\BWANA-MAIL-01-Autounattend.xml'
$pw = $x.SelectSingleNode("//*[local-name()='AutoLogon']/*[local-name()='Password']/*[local-name()='Value']").InnerText.Trim()
$sec = ConvertTo-SecureString -String $pw -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
Invoke-Command -VMName BWANA-MAIL-01 -Credential $cred -ScriptBlock {
    $rows = Get-Service MSExchangeTransport,MSExchangeFrontendTransport,MSExchangeDelivery,MSExchangeSubmission,MSExchangeIS,MSExchangeRPC,MSExchangeServiceHost -ErrorAction SilentlyContinue |
        Select-Object Name,Status,StartType
    $rows | ForEach-Object { $_.Name + ' ' + $_.Status + ' ' + $_.StartType }
} | ForEach-Object { Write-Host $_ }
