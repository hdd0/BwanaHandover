foreach ($vm in @("BWANA-DC01", "BWANA-DC02")) {
    Write-Output ("=== " + $vm + " ===")
    $v = Get-VM -Name $vm -ErrorAction SilentlyContinue
    if (-not $v) { Write-Output "VM NOT FOUND"; continue }
    Write-Output ("State=" + $v.State + " Uptime=" + $v.Uptime)
    $svc = Get-VMIntegrationService -VMName $vm -Name "Guest Service Interface" -ErrorAction SilentlyContinue
    if ($svc) { Write-Output ("GuestServiceInterface Enabled=" + $svc.Enabled + " PrimaryStatus=" + $svc.PrimaryStatusDescription) }
    else { Write-Output "Guest Service Interface NOT FOUND" }
    $kvps = Get-VMIntegrationService -VMName $vm -Name "Key-Value Pair Exchange" -ErrorAction SilentlyContinue
    if ($kvps) { Write-Output ("KVP Enabled=" + $kvps.Enabled) }
}
Write-Output "GUEST_SVC_DONE"
