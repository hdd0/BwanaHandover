$job = Start-Job { Invoke-Command -VMName 'BWANA-DC01' -ScriptBlock { (Get-CimInstance Win32_ComputerSystem).PartOfDomain } -ErrorAction Stop }
if(Wait-Job $job -Timeout 40){ "DC01 PSD: " + (Receive-Job $job) } else { "DC01 PSD: TIMEOUT (host thrashing)" }
Stop-Job $job -EA SilentlyContinue; Remove-Job $job -Force -EA SilentlyContinue
