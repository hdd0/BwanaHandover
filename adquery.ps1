$dse = New-Object System.DirectoryServices.DirectoryEntry('LDAP://192.168.150.10/RootDSE')
Write-Host "defaultNamingContext: $($dse.defaultNamingContext)"
Write-Host "configurationNamingContext: $($dse.configurationNamingContext)"
Write-Host "rootDomainNamingContext: $($dse.rootDomainNamingContext)"
Write-Host "dnsHostName: $($dse.dnsHostName)"
Write-Host "forestFunctionality: $($dse.forestFunctionality)"
Write-Host "domainFunctionality: $($dse.domainFunctionality)"
Write-Host "supportedLDAPVersion: $($dse.supportedLDAPVersion)"
