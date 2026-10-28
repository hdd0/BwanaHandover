$ErrorActionPreference = 'Continue'

$container = 'jenkins'
$javaBin = '/opt/java/openjdk/bin/java'

Write-Output '=== java presence ==='
docker exec $container sh -lc 'ls -l /opt/java/openjdk/bin/java 2>/dev/null || echo "no /opt/java/openjdk"; echo "JAVA_HOME=$JAVA_HOME"' 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output ''
Write-Output '=== wizard state ==='
docker exec $container sh -lc 'cat /var/jenkins_home/jenkins.install.UpgradeWizard.state 2>/dev/null || echo "(absent)"' 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output ''
Write-Output '=== security config ==='
docker exec $container sh -lc 'grep -o "<useSecurity>[^<]*" /var/jenkins_home/config.xml 2>/dev/null || echo "useSecurity: (unset)"; grep -o "jenkins.security.HudsonPrivateSecurityRealm" /var/jenkins_home/config.xml 2>/dev/null | head -1 || echo "securityRealm: (none)"' 2>&1 | ForEach-Object { Write-Output $_ }

Write-Output ''
Write-Output '=== jenkins-cli who-am-i with initial admin password ==='
docker exec $container sh -lc "PW=`$(cat /var/jenkins_home/secrets/initialAdminPassword); $javaBin -jar /usr/share/jenkins/jenkins.war WEB-INF/lib/jenkins-cli.jar -s http://localhost:8080/ -auth \"admin:`$PW\" who-am-i 2>&1" 2>&1 | ForEach-Object { Write-Output $_ }
