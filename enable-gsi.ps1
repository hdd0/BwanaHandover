foreach ($vm in @("BWANA-DC01", "BWANA-DC02")) {
    Enable-VMIntegrationService -VMName $vm -Name "Guest Service Interface"
    $svc = Get-VMIntegrationService -VMName $vm -Name "Guest Service Interface"
    Write-Output ($vm + " GuestServiceInterface Enabled=" + $svc.Enabled)
}
Write-Output "GSI_ENABLED"
