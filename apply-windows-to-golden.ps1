#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

$vmName = 'BWANA-GOLDEN-SRC'
$isoPath = 'C:\Users\howar\Downloads\26100.32230.260111-0550.lt_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
$vhdPath = 'C:\Hyper-V\AD\BWANA-DC01\BWANA-GOLDEN-SRC.vhdx'
$answerFile = 'C:\STEP\unattend\golden\Autounattend.xml'

# Stop VM if running
$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if ($vm -and $vm.State -ne 'Off') {
    "Stopping $vmName"
    Stop-VM -Name $vmName -Force -ErrorAction Stop
}

# Mount ISO
"Mounting ISO"
$iso = Mount-DiskImage -ImagePath $isoPath -StorageType ISO -Access ReadOnly
$isoDrive = ($iso | Get-Volume).DriveLetter
"ISO drive: $isoDrive`:"

$wimPath = "$isoDrive`:\sources\install.wim"
if (-not (Test-Path $wimPath)) {
    "install.wim not found at $wimPath; trying install.esd"
    $wimPath = "$isoDrive`:\sources\install.esd"
}
"Install image: $wimPath"

# Mount target VHD
"Mounting VHD"
Mount-DiskImage -ImagePath $vhdPath -Access ReadWrite | Out-Null
$disk = Get-DiskImage -ImagePath $vhdPath | Get-Disk
"Disk number: $($disk.Number)"

# Clean and initialize
Clear-Disk -Number $disk.Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction SilentlyContinue
Initialize-Disk -Number $disk.Number -PartitionStyle GPT

# Create partitions
$systemPart = New-Partition -DiskNumber $disk.Number -Size 100MB -GptType '{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}' | Format-Volume -FileSystem FAT32 -NewFileSystemLabel System -Confirm:$false
$msrPart = New-Partition -DiskNumber $disk.Number -Size 16MB -GptType '{e3c9e316-0b5c-4db8-817d-f92df00215ae}'
$windowsPart = New-Partition -DiskNumber $disk.Number -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel Windows -Confirm:$false

"Partitions created: System=$($systemPart.DriveLetter), Windows=$($windowsPart.DriveLetter)"

# Apply image
"Applying image (this will take a few minutes)"
$index = 1
# Find the right image index for Server 2025 Standard Desktop Experience
$images = Get-WindowsImage -ImagePath $wimPath
"Available images:"
$images | Select-Object ImageIndex, ImageName | Format-Table -AutoSize
$targetImage = $images | Where-Object { $_.ImageName -like '*Server 2025 Standard*Desktop*' } | Select-Object -First 1
if ($targetImage) {
    $index = $targetImage.ImageIndex
    "Using index $index: $($targetImage.ImageName)"
} else {
    "No Desktop Experience image found; using index 1"
}

Expand-WindowsImage -ImagePath $wimPath -Index $index -ApplyPath "$($windowsPart.DriveLetter):\" -ErrorAction Stop

# Run bcdboot
"Running bcdboot"
& bcdboot "$($windowsPart.DriveLetter):\Windows" /s "$($systemPart.DriveLetter):" /f UEFI
if ($LASTEXITCODE -ne 0) { "bcdboot failed with $LASTEXITCODE"; exit 1 }

# Copy answer file
"Copying answer file"
$pantherDir = "$($windowsPart.DriveLetter):\Windows\Panther\Unattend"
New-Item -ItemType Directory -Path $pantherDir -Force | Out-Null
Copy-Item -Path $answerFile -Destination "$pantherDir\Unattend.xml" -Force

# Dismount
"Dismounting VHD and ISO"
Dismount-DiskImage -ImagePath $vhdPath | Out-Null
Dismount-DiskImage -ImagePath $isoPath | Out-Null

# Remove DVD from VM (not needed)
$vm = Get-VM -Name $vmName
$dvd = $vm.DVDDrives | Select-Object -First 1
if ($dvd) {
    "Removing DVD drive"
    Remove-VMDvdDrive -VMName $vmName -ControllerNumber $dvd.ControllerNumber -ControllerLocation $dvd.ControllerLocation
}

# Remove answer disk from VM (we copied the file into the VHD)
$answerDisk = $vm.HardDrives | Where-Object { $_.Path -like '*answer-GOLDEN*' } | Select-Object -First 1
if ($answerDisk) {
    "Removing answer disk"
    Remove-VMHardDiskDrive -VMName $vmName -ControllerNumber $answerDisk.ControllerNumber -ControllerLocation $answerDisk.ControllerLocation
}

# Set boot order to HDD only
$hdd = $vm.HardDrives | Where-Object { $_.Path -like '*BWANA-GOLDEN-SRC.vhdx' } | Select-Object -First 1
$net = Get-VMNetworkAdapter -VMName $vmName | Select-Object -First 1
Set-VMFirmware -VMName $vmName -BootOrder $hdd, $net

# Start VM
"Starting VM"
Start-VM -Name $vmName

Start-Sleep -Seconds 5
$vm = Get-VM -Name $vmName
"State: $($vm.State), Uptime: $($vm.Uptime), Status: $($vm.Status)"
