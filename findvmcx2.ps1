Write-Host "=== E:\BWANA\Hyper-V ==="
Get-ChildItem -Path "E:\BWANA\Hyper-V" -Recurse -ErrorAction SilentlyContinue | Select FullName
Write-Host "=== search ProgramData for vmcx ==="
Get-ChildItem -Path "C:\ProgramData" -Recurse -Filter "*.vmcx" -ErrorAction SilentlyContinue | Select FullName
