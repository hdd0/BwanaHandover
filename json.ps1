$f = "$env:APPDATA\Docker\settings-store.json"
"mtime: " + (Get-Item $f).LastWriteTime
$raw = [System.IO.File]::ReadAllText($f)
"length: " + $raw.Length
try { $null = $raw | ConvertFrom-Json; Say 'x' 'ok' 'PS parse: VALID' } catch { "PS parse FAILED: " + $_.Exception.Message }
# Find non-printable / suspicious chars
$bad = @()
for($i=0;$i -lt $raw.Length;$i++){
  $c=[int][char]$raw[$i]
  if($c -lt 32 -and $c -notin 9,10,13){ $bad += "idx=$i code=$c" }
  if($c -eq 0xFEFF){ $bad += "idx=$i BOM" }
}
if($bad.Count){ "NONPRINTABLE: " + ($bad -join ', ') } else { "NONPRINTABLE: none" }
# Go json rejects unquoted/duplicated keys and trailing junk - try python
"--- head 200 ---"
$raw.Substring(0,[Math]::Min(200,$raw.Length))
