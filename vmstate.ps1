"=== Windows VMs: autologon registry (PowerShell Direct) ==="
$win = Get-VM | Where-Object { $_.State -eq 'Running' -and $_.Name -ne 'DockerDesktopVM' }
foreach($v in $win){
  $ps = $v.Name
  try {
    $o = Invoke-Command -VMName $ps -ScriptBlock {
      $k='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
      $p=Get-ItemProperty $k -ErrorAction SilentlyContinue
      $lock = Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -ErrorAction SilentlyContinue
      $id = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -ErrorAction SilentlyContinue
      [PSCustomObject]@{
        AutoAdminLogon = $p.AutoAdminLogon
        DefaultUserName = $p.DefaultUserName
        DefaultDomainName = $p.DefaultDomainName
        DomainJoined = (Get-CimInstance Win32_ComputerSystem).PartOfDomain
        Workgroup = (Get-CimInstance Win32_ComputerSystem).Workgroup
        ScreensaverOff = ($lock.PreserveScreensaver -eq 0)
        LockAfterIdle = $id.InactivityTimeoutSecs
      }
    } -ErrorAction Stop
    [PSCustomObject]@{ VM=$ps; AutoLogon=$o.AutoAdminLogon; User=$o.DefaultUserName; Domain=$o.DefaultDomainName; PartOfDomain=$o.DomainJoined; LockAfterIdle=$o.LockAfterIdle }
  } catch { [PSCustomObject]@{ VM=$ps; AutoLogon='ERR'; User=$_.Exception.Message.Substring(0,[Math]::Min(50,$_.Exception.Message.Length)); Domain=''; PartOfDomain=''; LockAfterIdle='' } }
}
