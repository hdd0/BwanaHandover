$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
Write-Output ("exists=" + (Test-Path $iso))
Write-Output ("bytes=" + (Get-Item $iso).Length)
Write-Output 'hashing (SHA256, ~30s)...'
(Get-FileHash -Path $iso -Algorithm SHA256).Hash | Write-Output
