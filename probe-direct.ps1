# probe PS Direct on both DCs (proves OS up + creds work)
$sec = Get-Content C:\STEP\unattend\secrets\admin.dpapi.txt | ConvertTo-SecureString
$cred = New-Object PSCredential('Administrator', $sec)
foreach ($vm in @('BWANA-DC01','BWANA-DC02')) {
  try {
    $h = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
    Write-Output ("PSDIRECT-OK: " + $vm + " hostname=" + $h)
  } catch { Write-Output ("PSDIRECT-WAIT: " + $vm + " (" + $_.Exception.Message.Split([Environment]::NewLine)[0] + ")") }
}
Write-Output DONE-PROBE
