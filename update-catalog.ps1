$ErrorActionPreference = 'Continue'
$root = 'C:\STEP\BwanaApp'
$enc = New-Object System.Text.UTF8Encoding($false)

# Only CURRENT-STATE catalog docs. Dated spec/plan docs are historical records - left untouched.
$edits = @(
  @{ File = 'docs\PROJECT_CATALOG.md'
     Old  = '| BwanaEmail | 0.1.0 | main | 1 | [hdd0/BwanaMail](https://github.com/hdd0/BwanaMail) |'
     New  = '| BwanaMail | 0.2.0 | main | 4 | [hdd0/BwanaMail](https://github.com/hdd0/BwanaMail) |' },

  @{ File = 'docs\AI_HANDOVER.md'
     Old  = 'The `BwanaEmail` local project maps to the existing private GitHub repository `hdd0/BwanaMail`, which was renamed on GitHub; its configured `hdd0/BwanaEmail` URL redirects. The catalog resolves this alias rather than treating the project as missing.'
     New  = 'The local project is now `C:\STEP\BwanaMail`, renamed from `BwanaEmail` on 2026-10-16. Its origin points directly at the private GitHub repository `hdd0/BwanaMail` rather than relying on the old `hdd0/BwanaEmail` redirect. The project is configured as the BwanaKhasu mail platform: Exchange Server 2019 primary on `BWANA-GOLDEN-SRC`, Stalwart secondary/DR, on-prem AD `ad.bwanakhasu.one` as identity authority, Gmail pulled into Exchange.' },

  @{ File = 'docs\PROJECT_BRIEFS.md'
     Old  = '| [BwanaEmail](https://github.com/hdd0/BwanaMail/blob/main/docs/PROJECT_IDEA_AND_ARCHITECTURE.md) | Local-first workspace concept for reading/managing multiple Gmail accounts using Lightpanda/CDP. | Setup/configuration notes exist; Gmail sign-in/token flow remains pending. Its GitHub repository was renamed to `hdd0/BwanaMail`; the configured old origin redirects to that repo. | Local Windows/browser integration is documented; future runtime placement and account connector boundaries require review. | No account authentication or mail operation was performed. |'
     New  = '| [BwanaMail](https://github.com/hdd0/BwanaMail/blob/main/docs/PROJECT_IDEA_AND_ARCHITECTURE.md) | Mail platform for the Bwana Khasu infrastructure. | Architecture decided 2026-10-16. Stalwart running and healthy as secondary/DR; Exchange 2019 planned as primary on `BWANA-GOLDEN-SRC` but **not installed**; Gmail pull planned. Local project renamed from `BwanaEmail`. | Stage 0 verification failed: target VM has no OS, memory raised 2 GB to 8 GB, DVD had no boot entry. | Blocked: Exchange CU13 is unsupported on Server 2025 (CU14+ required); install-media topology unresolved. See `docs/STAGE0_FINDINGS.md`. |' },

  @{ File = 'docs\project-ideas\REPO-MAP.md'
     Old  = '- `BwanaEmail` local identity stays `C:\STEP\BwanaEmail` (origin `https://github.com/hdd0/BwanaEmail.git`); its GitHub destination alias is `hdd0/BwanaMail`. Index links resolve BwanaEmail to BwanaMail explicitly.'
     New  = '- `BwanaMail` local identity is `C:\STEP\BwanaMail` (origin `https://github.com/hdd0/BwanaMail.git`), renamed from `BwanaEmail` on 2026-10-16. History is preserved across the rename; no GitHub redirect is relied on.'
  }
)

foreach ($e in $edits) {
  $p = Join-Path $root $e.File
  if (-not (Test-Path $p)) { Write-Output "MISSING: $($e.File)"; continue }
  $text = [System.IO.File]::ReadAllText($p)
  if ($text -notlike "*$($e.Old.Split('|')[0].Trim())*" -and $text.IndexOf($e.Old) -lt 0) {
    Write-Output "NO MATCH: $($e.File)"; continue
  }
  if ($text.IndexOf($e.Old) -ge 0) {
    $text = $text.Replace($e.Old, $e.New)
    [System.IO.File]::WriteAllText($p, $text, $enc)
    Write-Output "UPDATED: $($e.File)"
  } else {
    Write-Output "NO MATCH (exact): $($e.File)"
  }
}

Write-Output ""
Write-Output "=== Line-only fix in WIP file (NOT committed) ==="
$wip = Join-Path $root 'docs\project-ideas\README.md'
$t = [System.IO.File]::ReadAllText($wip)
$oldRow = '| BwanaEmail | `C:\STEP\BwanaEmail` (GitHub destination alias `hdd0/BwanaMail`) |'
$newRow = '| BwanaMail | `C:\STEP\BwanaMail` |'
if ($t.IndexOf($oldRow) -ge 0) {
  [System.IO.File]::WriteAllText($wip, $t.Replace($oldRow, $newRow), $enc)
  Write-Output "UPDATED (left uncommitted, file had pre-existing WIP): docs\project-ideas\README.md"
} else { Write-Output "row not found" }

Write-Output ""
Write-Output "=== REMAINING BwanaEmail REFS ==="
Get-ChildItem -Path $root -Recurse -File -Include *.md -ErrorAction SilentlyContinue |
  Select-String -Pattern 'BwanaEmail' -SimpleMatch -List |
  Select-Object Path, LineNumber | Format-Table -AutoSize