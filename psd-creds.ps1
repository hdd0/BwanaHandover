$vm = 'BWANA-GOLDEN-SRC'
$pw  = 'Arevbuh?_xuzexR5$x=aNZce'
$users = @('Administrator', '.\Administrator', "$env:COMPUTERNAME\Administrator")

foreach ($u in $users) {
  $cred = New-Object System.Management.Automation.PSCredential($u, (ConvertTo-SecureString $pw -AsPlainText -Force))
  try {
    $r = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock { "$env:COMPUTERNAME OK" } -ErrorAction Stop
    Write-Host "SUCCESS with '$u' -> $r"
    break
  } catch {
    Write-Host "FAIL '$u' -> $($_.Exception.Message)"
  }
}