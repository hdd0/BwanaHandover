try {
  $dse = New-Object System.DirectoryServices.DirectoryEntry('LDAP://192.168.150.10/RootDSE')
  $dse.RefreshCache()
  Write-Host "Properties count: $($dse.Properties.Count)"
  foreach ($p in $dse.Properties.PropertyNames) { Write-Host "$p = $($dse.Properties[$p])" }
} catch { Write-Host "ERR: $($_.Exception.Message)" }
