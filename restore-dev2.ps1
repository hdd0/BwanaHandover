$ErrorActionPreference = "Continue"
function Launch($workdir, $argline, $label) {
  $si = New-Object System.Diagnostics.ProcessStartInfo
  $si.FileName = "C:\Program Files\nodejs\npm.cmd"
  $si.Arguments = $argline
  $si.WorkingDirectory = $workdir
  $si.UseShellExecute = $false
  $si.CreateNoWindow = $true
  $si.RedirectStandardOutput = $false
  $si.RedirectStandardError = $false
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $si
  $null = $p.Start()
  Write-Output ("LAUNCHED " + $label + " pid=" + $p.Id)
}

Launch "C:\STEP\architect-platform" "run dev -- --hostname 127.0.0.1 --port 3010" "architect-platform:3010"
Launch "C:\STEP\openship"           "run dev"                                    "openship:3015"
Start-Sleep 15
foreach ($pt in @(3010,3015)) {
  $c = Get-NetTCPConnection -LocalPort $pt -State Listen -ErrorAction SilentlyContinue
  if ($c) { Write-Output ("PORT " + $pt + " LISTEN pid=" + $c[0].OwningProcess) } else { Write-Output ("PORT " + $pt + " still down") }
}