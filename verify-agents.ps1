$d = 'C:\STEP\BwanaAI\BwanaAI\agents'

Get-ChildItem $d -Directory | ForEach-Object {
    $s = Get-ChildItem $_.FullName -Recurse -File | Measure-Object Length -Sum
    '{0,-10} {1,6} files {2,8:N1} MB' -f $_.Name, $s.Count, ($s.Sum / 1MB)
}
'--- largest files ---'
Get-ChildItem $d -Recurse -File | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object {
    '{0,8:N2} MB  {1}' -f ($_.Length / 1MB), $_.FullName.Replace($d, '')
}

'--- secret scan ---'
$patterns = 'sk-tinyfish-', 'L8Rp9M8t8O7f9C7s7t707An8zS56n9R9F6YRa7E7X', 'd914f1d0421d04500d9da18d00c6165b0ee767609bb5d05b67710306ecb08242', 'gho_[A-Za-z0-9]{20,}', 'BEGIN (RSA|OPENSSH) PRIVATE KEY'
$hits = Get-ChildItem $d -Recurse -File |
    Where-Object { $_.Name -ne 'export-agents.ps1' } |
    Select-String -Pattern $patterns -ErrorAction SilentlyContinue
if ($hits) {
    $hits | ForEach-Object { "LEAK: $($_.Path):$($_.LineNumber)" }
} else {
    'clean - no secrets found'
}
