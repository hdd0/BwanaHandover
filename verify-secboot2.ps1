$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$pr = New-Object Security.Principal.WindowsPrincipal($id)
Write-Host ("User      : " + $id.Name)
Write-Host ("Elevated  : " + $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
Write-Host ""

# Read firmware state via nested WMI on the VM settings object
$ns = 'root\virtualization\v2'
$vm = Get-CimInstance -Namespace $ns -ClassName MSFT_VirtualMachine -Filter "ElementName='BWANA-DC02'"
Write-Host ("CIM VM obj null? " + ($null -eq $vm))
if ($vm) {
    Write-Host ("  SecureBootEnabled : " + $vm.SecureBootEnabled)
    Write-Host ("  SecureBootTemplate: " + $vm.SecureBootTemplate)
    $sett = Get-CimAssociatedInstance -InputObject $vm -ResultClassName MSFT_VirtualMachineSettingsSetting
    $sett | Select-Object SecureBootEnabled,SecureBootTemplate,BootOrder | Format-List
}
