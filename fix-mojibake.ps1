$files = @(
  'C:\STEP\AGENTS.md',
  'C:\Users\howar\.config\opencode\AGENTS.md',
  'C:\STEP\BwanaMail\AGENTS.md'
)

$utf8   = New-Object System.Text.UTF8Encoding($false)
$cp1252 = [System.Text.Encoding]::GetEncoding(1252)

# mojibake marker chars, built from code points so this script stays pure ASCII
$mojiMarker = [string][char]0x00E2 + [char]0x20AC   # a-circumflex + euro
$arrow      = [string][char]0x2192                  # rightwards arrow
$emdash     = [string][char]0x2014                  # em dash

foreach ($f in $files) {
  Copy-Item $f "$f.mojibake.bak" -Force

  $moji = [System.IO.File]::ReadAllText($f, $utf8)
  $origBytes = $cp1252.GetBytes($moji)
  [System.IO.File]::WriteAllBytes($f, $origBytes)

  # verify round-trip: file must decode as strict UTF-8
  $strict = New-Object System.Text.UTF8Encoding($false, $true)
  $check  = [System.IO.File]::ReadAllText($f, $strict)
  $bad    = ([regex]::Matches($check, [regex]::Escape($mojiMarker))).Count
  $nArrow = ([regex]::Matches($check, [regex]::Escape($arrow))).Count
  $nEm    = ([regex]::Matches($check, [regex]::Escape($emdash))).Count
  Write-Host ("{0}  mojibake={1}  arrows={2}  emdash={3}  bytes={4}" -f $f, $bad, $nArrow, $nEm, (Get-Item $f).Length)
}