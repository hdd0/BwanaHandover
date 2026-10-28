Get-VM -Name 'BWANA-GOLDEN-SRC' | Select-Object Name, State, Status | Format-List
Get-Process | Where-Object { $_.ProcessName -in @('vmwp','vmcompute','vmconnect','mmc','virtmgmt') } | Select-Object ProcessName, Id | Format-Table -AutoSize
