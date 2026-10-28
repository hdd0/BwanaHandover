Get-ChildItem -Path 'C:\STEP' -Directory | Where-Object { Test-Path (Join-Path $_.FullName '.git') } | ForEach-Object {
    $name = $_.Name
    Write-Host "Fetching $name ..."
    try {
        Push-Location $_.FullName
        $res = git fetch --all 2>&1
        Write-Host ("  $name: $res")
        Pop-Location
    } catch {
        Write-Host ("  $name: ERROR $($_)")
    }
} 2>&1 | Tee-Object -FilePath 'C:\Users\howar\AppData\Local\Temp\opencode\fetch-results.log'
