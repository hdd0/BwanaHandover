$s1 = Get-Process | Select-Object Id,Name,CPU
Start-Sleep -Seconds 6
$s2 = Get-Process | Select-Object Id,Name,CPU
$n = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$map = @{}
foreach($p in $s2){ if($p.CPU -ne $null){ $map[$p.Id] = $p } }
$rows = foreach($p in $s1){
  if($p.CPU -ne $null -and $map.ContainsKey($p.Id)){
    $d = $map[$p.Id].CPU - $p.CPU
    if($d -gt 0.05){ [PSCustomObject]@{ Name=$p.Name; Id=$p.Id; CpuPct=[math]::Round($d/6*100/$n,1); Cores=[math]::Round($d/6,2) } }
  }
}
"Logical CPUs: $n"
"=== LIVE CPU BURN (top 15) ==="
$rows | Sort-Object CpuPct -Descending | Select-Object -First 15 | Format-Table -AutoSize
"Total app CPU pct: " + [math]::Round((($rows | Measure-Object CpuPct -Sum).Sum),1)
