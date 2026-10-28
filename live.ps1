$list = Get-NetTCPConnection -State Listen | Where-Object {$_.LocalPort -gt 1023 -and $_.LocalPort -lt 60000} | Select-Object -ExpandProperty LocalPort -Unique | Sort-Object
$ok = @()
foreach($p in $list){
  try{
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:$p/" -UseBasicParsing -TimeoutSec 3 -MaximumRedirection 0 -ErrorAction Stop
    $ok += [PSCustomObject]@{Port=$p; Code=$r.StatusCode; Live=$true}
  } catch {
    $code = $_.Exception.Response.StatusCode.value__
    if($code){ $ok += [PSCustomObject]@{Port=$p; Code=$code; Live=$true} }
  }
}
$ok | Sort-Object Port | Format-Table -AutoSize
"Live services: $($ok.Count)"
