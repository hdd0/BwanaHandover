"=== Is there live work in the WSL distros I would shut down? ==="
foreach($d in @('Ubuntu','kali-linux')){
  $job = Start-Job -ArgumentList $d -ScriptBlock { param($dd) & wsl.exe -d $dd -e sh -c "ps -eo comm= | sort | uniq -c | sort -rn | head -12" 2>&1 }
  if(Wait-Job $job -Timeout 20){ "--- $d ---"; Receive-Job $job } else { "--- $d --- probe timed out" }
  Stop-Job $job -EA SilentlyContinue; Remove-Job $job -Force -EA SilentlyContinue
}
