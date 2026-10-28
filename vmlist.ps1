Get-VM | ForEach-Object { Write-Host ("[" + $_.Name + "] State=" + $_.State) }
