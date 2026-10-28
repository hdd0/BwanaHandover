$ErrorActionPreference = 'Continue'

Write-Output '=== identify OKD/NAS guests by open ports ==='
foreach ($n in @('BWANA-OKD-01', 'BWANA-NAS-01')) {
    $ips = Get-VMNetworkAdapter -VMName $n | Select-Object -ExpandProperty IPAddresses -ErrorAction SilentlyContinue |
        Where-Object { $_ -match '^\d+\.' }
    foreach ($ip in $ips) {
        $res = [ordered]@{ VM = $n; IP = $ip }
        foreach ($p in @(22, 5985, 3389, 445, 80)) {
            $c = New-Object System.Net.Sockets.TcpClient
            try {
                $a = $c.BeginConnect($ip, $p, $null, $null)
                $ok = $a.AsyncWaitHandle.WaitOne(1200)
                $res["p$p"] = ($ok -and $c.Connected)
            }
            catch { $res["p$p"] = $false }
            finally { $c.Dispose() }
        }
        Write-Output ('  ' + $n + ' ' + $ip + ' ssh22=' + $res['p22'] + ' winrm5985=' + $res['p5985'] + ' rdp3389=' + $res['p3389'] + ' smb445=' + $res['p445'] + ' http80=' + $res['p80'])
    }
}

Write-Output ''
Write-Output '=== freeing RAM: stopping BWANA-OKD-01 (OKD-02/03/BOOTSTRAP already off => cluster already down) ==='
$okd = Get-VM -Name BWANA-OKD-01
if ($okd.State -eq 'Running') {
    Write-Output ('  stopping BWANA-OKD-01 (assigned ' + [math]::Round($okd.MemoryAssigned / 1GB, 2) + ' GB)')
    Stop-VM -Name BWANA-OKD-01 -Force
    $deadline = (Get-Date).AddMinutes(5)
    while ((Get-VM -Name BWANA-OKD-01).State -ne 'Off') {
        if ((Get-Date) -gt $deadline) { Write-Output '  WARN timeout waiting for stop'; break }
        Start-Sleep -Seconds 5
    }
    Write-Output ('  state now = ' + (Get-VM -Name BWANA-OKD-01).State)
} else { Write-Output ('  already ' + $okd.State) }

Start-Sleep -Seconds 10
$os = Get-CimInstance Win32_OperatingSystem
Write-Output ''
Write-Output ('Host free RAM now = ' + [math]::Round($os.FreePhysicalMemory / 1MB, 2) + ' GB of ' + [math]::Round($os.TotalVisibleMemorySize / 1MB, 2) + ' GB')