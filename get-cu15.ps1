$ErrorActionPreference = 'Continue'
$url  = 'https://download.microsoft.com/download/7/0/a/70a4d908-eacb-426e-ad9f-e7768e27f873/ExchangeServer2019-x64-cu15.iso'
$dest = 'C:\Users\howar\Downloads\ExchangeServer2019-x64-cu15.iso'

if (Test-Path $dest) { Write-Output "Already present: $dest ($([math]::Round((Get-Item $dest).Length/1GB,2)) GB)"; exit 0 }

Write-Output "=== HEAD CHECK ==="
try {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Method = 'HEAD'
    $req.Timeout = 60000
    $resp = $req.GetResponse()
    $len = $resp.ContentLength
    Write-Output ("HTTP {0}" -f [int]$resp.StatusCode)
    Write-Output ("Content-Length: {0} bytes ({1} GB)" -f $len, [math]::Round($len/1GB,2))
    Write-Output ("Content-Type: {0}" -f $resp.ContentType)
    $resp.Close()
    $ok = $true
} catch {
    Write-Output ("HEAD failed: {0}" -f $_.Exception.Message)
    $ok = $false
}

if (-not $ok) { Write-Output "Aborting download - source not reachable."; exit 1 }

Write-Output ""
Write-Output "=== FREE SPACE CHECK ==="
$c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
Write-Output ("C: free {0} GB (need ~{1} GB)" -f [math]::Round($c.FreeSpace/1GB,1), [math]::Round($len/1GB,1))

Write-Output ""
Write-Output "=== START BITS TRANSFER (background, resumable) ==="
try {
    Import-Module BitsTransfer -ErrorAction Stop
    $job = Start-BitsTransfer -Source $url -Destination $dest -DisplayName 'Exchange2019-CU15-ISO' -Description 'Exchange Server 2019 CU15 (required for Server 2025 support)' -Asynchronous -ErrorAction Stop
    Write-Output ("JobId  : {0}" -f $job.JobId)
    Write-Output ("State  : {0}" -f $job.JobState)
    Write-Output ("Target : {0}" -f $dest)
    Write-Output ""
    Write-Output "It runs in the background and survives reboots. Check progress with:"
    Write-Output "  Get-BitsTransfer -Name 'Exchange2019-CU15-ISO' | Select-Object BytesTransferred, JobState"
} catch {
    Write-Output ("BITS failed: {0}" -f $_.Exception.Message)
    Write-Output "Falling back to a plain background download via BITS WebClient."
    $wc = New-Object System.Net.WebClient
    $job = Start-Job -ScriptBlock {
        param($u, $d)
        $c2 = New-Object System.Net.WebClient
        $c2.DownloadFile($u, $d)
    } -ArgumentList $url, $dest
    Write-Output ("Fallback job id: {0}" -f $job.Id)
}