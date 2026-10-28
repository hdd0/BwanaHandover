# Method 1: AppCompatFlags RUNASADMIN (every launch elevates, UAC prompts)
# Method 2: Desktop shortcut with RunAs-admin byte set
$ErrorActionPreference = 'Stop'
$exe = 'C:\Program Files\Microsoft VS Code\Code.exe'
if (-not (Test-Path $exe)) { throw "Not found: $exe" }

# --- Method 1: registry ---
$layers = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
if (-not (Test-Path $layers)) { New-Item -Path $layers -Force | Out-Null }
$cur = (Get-ItemProperty -Path $layers -Name $exe -ErrorAction SilentlyContinue).$exe
if ($cur -notlike '*RUNASADMIN*') {
  Set-ItemProperty -Path $layers -Name $exe -Value '~ RUNASADMIN'
  Write-Output 'METHOD1-CREATED: RUNASADMIN set for Code.exe'
} else { Write-Output "METHOD1-OK: already set ($cur)" }

# --- Method 2: admin shortcut on desktop ---
$desktop = [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desktop 'VS Code (Admin).lnk'
$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = $exe
$sc.WorkingDirectory = 'C:\Program Files\Microsoft VS Code'
$sc.Description = 'VS Code always elevated (UAC prompts)'
$sc.Save()
# Set RunAs-admin bit: byte 0x15 |= 0x20
$b = [IO.File]::ReadAllBytes($lnk)
$b[0x15] = $b[0x15] -bor 0x20
[IO.File]::WriteAllBytes($lnk, $b)
$verify = [IO.File]::ReadAllBytes($lnk)[0x15]
Write-Output ("METHOD2-OK: shortcut created, RunAs bit = " + (($verify -band 0x20) -eq 0x20))
Write-Output "VERIFY-REGISTRY:"
reg query "HKCU\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" /v "$exe"
