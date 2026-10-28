$ErrorActionPreference = 'Continue'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
Write-Output "=== MOUNT ISO (read-only) to read install.wim ==="
$mnt = 'C:\Users\howar\AppData\Local\Temp\opencode\iso'
if (-not (Test-Path $mnt)) { New-Item -ItemType Directory -Path $mnt -Force | Out-Null }
$img = $null
try {
    $img = Mount-DiskImage -ImagePath $iso -PassThru -ErrorAction Stop
    $vol = $img | Get-Volume
    $drive = $vol.DriveLetter
    Write-Output "ISO mounted at ${drive}:\"
    Write-Output ""
    Write-Output "=== INSTALL.WIM INDEXES ==="
    & dism.exe "/Image:$drive`\sources\install.wim" /Get-ImageInfo 2>&1 |
        Select-String -Pattern 'Index|Image Name|Edition|Architecture|Version|Installation Type|Size' |
        ForEach-Object { $_.Line.Trim() }
    Write-Output ""
    Write-Output "=== sources listing (key files) ==="
    foreach ($f in @('install.wim','boot.wim','setup.exe')) {
        $p = "${drive}:\sources\$f"
        if (Test-Path $p) { Write-Output ("  {0} : {1} MB" -f $f, [math]::Round((Get-Item $p).Length/1MB,1)) } else { Write-Output "  $f : absent" }
    }
    $drv = $drive
} catch {
    Write-Output "Mount failed: $($_.Exception.Message)"
    exit 1
}
Set-Content -Path 'C:\Users\howar\AppData\Local\Temp\opencode\iso-drive.txt' -Value $drv
Write-Output ""
Write-Output "ISO_DRIVE=$drv"