param([string]$Root = "C:\STEP")
$repos = Get-ChildItem -Directory -Path $Root | Where-Object { $_.Name -match '^Bwana' -or $_.Name -match '^(HOWARDDAVIDJAMBO|africa-infra|phil-bridge|-malawi-social-intel|pop-planner|vod|videoondemand)$' }
$jobs = @()
foreach ($r in $repos) {
    $git = Join-Path $r.FullName ".git"
    if (Test-Path $git) {
        $job = Start-Job -ScriptBlock {
            param($dir)
            Push-Location $dir
            try { git fetch --all 2>&1 } catch { Write-Output "ERR: $_" }
            Pop-Location
        } -ArgumentList (Join-Path $r.FullName)
        $jobs += New-Object PSJobJobData -Property @{ Name=$r.Name; Status=$null; Result=$null; Job=$job }
    }
}
Write-Host "Started $($jobs.Count) background jobs"
Start-Sleep -Seconds 10
Write-Host "Progress:"
$jobs | ForEach-Object {
    if ($_.Job.State -eq 'Completed') {
        $result = Receive-Job -Job $_.Job 2>$null
        $status = if ($result) { "OK: $result" } else { "Done" }
        Write-Host "$($_.Name): $status" -ForegroundColor DarkGray
    } else {
        $state = $_.Job.State
        Write-Host "$($_.Name): $state ..." -ForegroundColor DarkGray
    }
}
