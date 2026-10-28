# OpenShip WSL Keeper - runs at boot, keeps WSL Ubuntu alive with OpenShip
# Uses interactive wsl.exe with piped stdin to run startup then sleep forever

$script = @"
set -e
cd /root/.openship/compose
docker compose up -d --remove-orphans
exec sleep infinity
"@

# Pipe to interactive wsl.exe (no -e) - this blocks until EOF
$proc = Start-Process wsl.exe -ArgumentList '-d', 'Ubuntu' -RedirectStandardInput $true -RedirectStandardOutput 'C:\Users\howar\AppData\Local\Temp\opencode\keeper-out.txt' -RedirectStandardError 'C:\Users\howar\AppData\Local\Temp\opencode\keeper-err.txt' -PassThru

# Write the script to stdin, then close (EOF) which will make wsl.exe run it and then sleep infinity
$proc.StandardInput.Write($script)
$proc.StandardInput.Close()

# The process will now run the script and exec sleep infinity, blocking forever
$proc.WaitForExit()