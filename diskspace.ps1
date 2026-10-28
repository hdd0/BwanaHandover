Get-PSDrive C | Select-Object @{n='UsedGB';e={[math]::Round($_.Used/1GB,1)}}, @{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}} | Format-Table -AutoSize | Out-String | Write-Output
Get-PhysicalDisk | Select-Object DeviceId, @{n='SizeGB';e={[math]::Round($_.Size/1GB,0)}}, MediaType | Format-Table -AutoSize | Out-String | Write-Output
