$ErrorActionPreference = 'Continue'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
$plain = $cred.GetNetworkCredential().Password

$s = New-PSSession -VMName BWANA-DC02 -Credential $cred -ErrorAction Stop
try {
    Invoke-Command -Session $s -ScriptBlock {
        param($g, $p)
        $ErrorActionPreference = 'Continue'
        try {
            & $g -UserName 'Administrator' -Domain 'BWANA' -Password $p *>&1 | ForEach-Object {
                Write-Output ("LINE [" + $_ + "]")
            }
        }
        catch {
            Write-Output 'CAUGHT-BY-DIAG:'
            Write-Output ("  msg    : " + $_.Exception.Message)
            Write-Output ("  script : " + $_.InvocationInfo.ScriptName)
            Write-Output ("  line   : " + $_.InvocationInfo.ScriptLineNumber)
            Write-Output ("  text   : " + $_.InvocationInfo.Line.Trim())
            Write-Output ("  cat    : " + $_.CategoryInfo.Category)
            Write-Output ("  fqid   : " + $_.FullyQualifiedErrorId)
        }
    } -ArgumentList @("$env:SystemRoot\Temp\set-lab-desktop.ps1", $plain)
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }