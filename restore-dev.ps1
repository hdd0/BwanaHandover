$ErrorActionPreference = "Continue"
$DETACH = 0x00000008  # DETACHED_PROCESS | 0x00000010 CREATE_NEW_CONSOLE

function Launch($workdir, $argline, $label) {
  $si = New-Object System.Diagnostics.ProcessStartInfo
  $si.FileName = "C:\Program Files\nodejs\npm.cmd"
  $si.Arguments = $argline
  $si.WorkingDirectory = $workdir
  $si.UseShellExecute = $false
  $si.CreateNoWindow = $true
  $si.RedirectStandardOutput = $true
  $si.RedirectStandardError = $true
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $si
  $null = $p.Start()
  Write-Output ("LAUNCHED " + $label + " pid=" + $p.Id + " :: " + $argline)
}

Launch "C:\STEP\architect-platform" "run dev -- --hostname 127.0.0.1 --port 3010" "architect-platform:3010"
Launch "C:\STEP\openship"           "run dev"                                    "openship:3015"
Launch "C:\STEP\stride"             "run dev"                                    "stride:3300"
Launch "C:\STEP\cyberdeck\cloudshell" "run dev"                                  "cloudshell:3100"

Start-Sleep -Seconds 25
foreach ($pt in @(3010,3015,3300,3100)) {
  $c = Get-NetTCPConnection -LocalPort $pt -State Listen -ErrorAction SilentlyContinue
  if ($c) { Write-Output ("PORT " + $pt + " LISTEN pid=" + $c[0].OwningProcess) } else { Write-Output ("PORT " + $pt + " still down") }
}
