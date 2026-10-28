$ErrorActionPreference = 'Continue'
$iso = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'

Write-Output '=== VIRTUAL MACHINES ==='
Get-VM | ForEach-Object {
    $v = $_
    $disks = (Get-VMHardDiskDrive -VMName $v.Name -ErrorAction SilentlyContinue | ForEach-Object { Split-Path $_.Path -Leaf }) -join ' | '
    $sw = (Get-VMNetworkAdapter -VMName $v.Name -ErrorAction SilentlyContinue | ForEach-Object { $_.SwitchName }) -join ','
    [pscustomobject]@{
        Name     = $v.Name
        State    = $v.State
        Gen      = $v.Generation
        Cpu      = $v.ProcessorCount
        MemGB    = [math]::Round($v.MemoryAssigned / 1GB, 2)
        Switch   = $sw
        Disks    = $disks
    }
} | Format-Table -AutoSize -Wrap

Write-Output ''
Write-Output '=== HOST FREE SPACE ==='
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } |
    Select-Object Name, @{n = 'FreeGB'; e = { [math]::Round($_.Free / 1GB, 1) } } | Format-Table -AutoSize

Write-Output ''
Write-Output '=== SERVER 2025 ISO INSTALL.WIM IMAGES ==='
if (Test-Path $iso) {
    Write-Output ("ISO: " + (Get-Item $iso).FullName + "  " + [math]::Round((Get-Item $iso).Length / 1GB, 2) + " GB")
    $mount = Mount-DiskImage -ImagePath $iso -PassThru -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $letter = ($mount | Get-Volume).DriveLetter
    if ($letter) {
        $wim = "$letter`:sources\install.wim"
        Write-Output ("WIM: " + $wim)
        & dism.exe /English /Get-WimInfo "/WimFile:$wim" | Select-String -Pattern 'Index|Name|Edition|Architecture|Version' | ForEach-Object { Write-Output $_.Line.Trim() }
        Dismount-DiskImage -ImagePath $iso | Out-Null
    }
    else { Write-Output 'FAIL: ISO did not expose a volume letter.' }
}
else { Write-Output 'FAIL: ISO not found.' }

Write-Output ''
Write-Output '=== EXCHANGE ISO ==='
$ex = 'C:\Users\howar\Downloads\ExchangeServer2019-x64-CU13.ISO'
if (Test-Path $ex) {
    Write-Output ("ISO: " + (Get-Item $ex).FullName + "  " + [math]::Round((Get-Item $ex).Length / 1GB, 2) + " GB")
}
else { Write-Output 'FAIL: Exchange ISO not found.' }