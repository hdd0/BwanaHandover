Get-VM | Where-Object {$_.State -eq 'Running'} | ForEach-Object {
  $nics = Get-VMNetworkAdapter -VM $_
  [PSCustomObject]@{
    Name = $_.Name
    Switch = (($nics | ForEach-Object { $_.SwitchName }) -join ',')
    VLAN = (($nics | ForEach-Object { $_.VlanId }) -join ',')
    IP = (($nics | ForEach-Object { ($_.IPAddresses | Where-Object {$_ -match '^\d+\.'}) -join '/' }) -join ' ; ')
  }
} | Format-Table -AutoSize -Wrap
