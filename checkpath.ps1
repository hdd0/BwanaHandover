Write-Host "Test VHD:" (Test-Path "E:\BWANA\Hyper-V\BWANA-EXCH-01\BWANA-EXCH-01.vhdx")
Write-Host "List E:\BWANA\Hyper-V:"
Get-ChildItem "E:\BWANA\Hyper-V" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.FullName }
Write-Host "List E:\BWANA\Hyper-V\BWANA-EXCH-01:"
Get-ChildItem "E:\BWANA\Hyper-V\BWANA-EXCH-01" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host $_.Name $_.Length }
