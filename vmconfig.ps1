Write-Host "=== Hyper-V VM config dir ==="
Get-ChildItem "C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines" -ErrorAction SilentlyContinue | Select Name,Length,LastWriteTime
Write-Host "=== EXCH-01 VHD exists? ==="
Test-Path "E:\BWANA\Hyper-V\BWANA-EXCH-01\BWANA-EXCH-01.vhdx"
Write-Host "=== Searching for exch config ==="
Get-ChildItem -Path "C:\ProgramData\Microsoft\Windows\Hyper-V" -Recurse -Filter "*EXCH*" -ErrorAction SilentlyContinue | Select FullName
