# Runs Set-JenkinsAdminPassword.ps1 using a password supplied in the
# JENKINS_ADMIN_PW environment variable. The value is converted to a
# SecureString in memory and never written to disk or echoed.
$ErrorActionPreference = 'Stop'
$plain = $env:JENKINS_ADMIN_PW
if (-not $plain) { throw 'JENKINS_ADMIN_PW is not set.' }
$secure = ConvertTo-SecureString -String $plain -AsPlainText -Force
$plain = $null
& 'C:\Users\howar\RiderProjects\BwanaPlatform\jenkins\Set-JenkinsAdminPassword.ps1' -AdminPassword $secure -UserName 'admin'
exit $LASTEXITCODE
