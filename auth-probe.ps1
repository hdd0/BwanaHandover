$ErrorActionPreference = "Continue"
$pw = ConvertTo-SecureString "BwanaLab!2026#Temp" -AsPlainText -Force
$forms = @("Administrator@ad.bwanakhasu.one", "BWANA\Administrator", "ad.bwanakhasu.one\Administrator")
foreach ($vm in @("BWANA-DC02", "BWANA-DC01")) {
    foreach ($u in $forms) {
        $cred = New-Object System.Management.Automation.PSCredential($u, $pw)
        try {
            $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop
            Write-Output ("SUCCESS vm=" + $vm + " user=" + $u + " hostname=" + $r)
        } catch {
            Write-Output ("FAIL vm=" + $vm + " user=" + $u + " :: " + $_.Exception.Message)
        }
    }
}
Write-Output "AUTH_PROBE_DONE"
