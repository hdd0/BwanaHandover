$vm = 'BWANA-GOLDEN-SRC'
$cred = New-Object System.Management.Automation.PSCredential(
  '.\Administrator',
  (ConvertTo-SecureString 'Arevbuh?_xuzexR5$x=aNZce' -AsPlainText -Force)
)

try {
  $s = Invoke-Command -VMName $vm -Credential $cred -ScriptBlock {
    [pscustomobject]@{
      Computer  = $env:COMPUTERNAME
      SetupKey  = (Test-Path 'C:\Windows\Panther\Unattend.xml')
      Goldendisk= (Test-Path 'C:\goldendisk')
      NetProfile= (Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty InterfaceAlias)
      Adapters  = ((Get-NetAdapter | ForEach-Object { "$($_.Name)=$($_.Status)/$($_.MacAddress)" }) -join ' | ')
      IPv4      = ((Get-NetIPAddress -AddressFamily IPv4 | ForEach-Object { "$($_.InterfaceAlias):$($_.IPAddress)" }) -join ' | ')
      OOBEKey   = (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\MiniNT')
      LogonUI   = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI' -ErrorAction SilentlyContinue).LastLoggedOnUser
    }
  } -ErrorAction Stop
  $s | Format-List
} catch {
  Write-Host "PowerShell Direct FAILED: $($_.Exception.Message)"
}