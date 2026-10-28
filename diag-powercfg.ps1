$ErrorActionPreference = 'Continue'
$sec = ConvertTo-SecureString ((Get-Content 'C:\STEP\unattend\secrets\admin.dpapi.txt' -Raw).Trim())
$cred = New-Object System.Management.Automation.PSCredential('Administrator@ad.bwanakhasu.one', $sec)
$s = New-PSSession -VMName BWANA-DC02 -Credential $cred -ErrorAction Stop
try {
    Invoke-Command -Session $s -ScriptBlock {
        $ErrorActionPreference = 'Continue'
        Write-Output '=== active scheme ==='
        (& powercfg.exe /getactivescheme 2>&1 | Out-String).Trim()
        Write-Output ''
        Write-Output '=== powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE (raw) ==='
        (& powercfg.exe /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 2>&1 | Out-String)
        Write-Output ''
        Write-Output '=== registry: per-user active scheme values ==='
        $active = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -Name ActivePowerScheme -EA SilentlyContinue).ActivePowerScheme
        Write-Output ("ActivePowerScheme = " + $active)
        $root = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$active"
        foreach ($pair in @(
                @{ n = 'display/VIDEOIDLE'; s = '{4f3e7100-e61f-11a0-b440-00a0c91c2828}'; v = '{5ca83367-6e45-459f-a27b-476b1d01c936}' },
                @{ n = 'sleep/STANDBYIDLE'; s = '{4f3e7100-e61f-11a0-b440-00a0c91c2828}'; v = '{ac0dc15a-6443-4a33-95cc-ef70b66109c7}' },
                @{ n = 'disk/DISKIDLE'; s = '{4f3e7100-e61f-11a0-b440-00a0c91c2828}'; v = '{6738e2c4-e8f5-4366-ac7c-6d7e70c9e48c}' }
            )) {
            $p = "$root\$($pair.s)\$($pair.v)"
            $ac = (Get-ItemProperty $p -Name ACSettingIndex -EA SilentlyContinue).ACSettingIndex
            $dc = (Get-ItemProperty $p -Name DCSettingIndex -EA SilentlyContinue).DCSettingIndex
            Write-Output ("  " + $pair.n.PadRight(18) + " AC=" + $ac + " DC=" + $dc)
        }
    }
}
finally { Remove-PSSession $s -ErrorAction SilentlyContinue }