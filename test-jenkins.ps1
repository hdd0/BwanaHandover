# Runs Test-Jenkins.ps1 using a password supplied in JENKINS_ADMIN_PW.
$ErrorActionPreference = 'Stop'
$plain = $env:JENKINS_ADMIN_PW
if (-not $plain) { throw 'JENKINS_ADMIN_PW is not set.' }
$secure = ConvertTo-SecureString -String $plain -AsPlainText -Force
$plain = $null
& 'C:\Users\howar\RiderProjects\BwanaPlatform\jenkins\Test-Jenkins.ps1' -AdminPassword $secure -UserName 'admin'
exit $LASTEXITCODE
