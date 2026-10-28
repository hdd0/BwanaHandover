$sw=[Diagnostics.Stopwatch]::StartNew()
try {
  $cs = New-PSSession -VMName 'BWANA-DC01' -ErrorAction Stop
  "PSD connect OK in $([math]::Round($sw.Elapsed.TotalSeconds,1))s"
  $r = Invoke-Command -Session $cs -ScriptBlock {
    [PSCustomObject]@{
      Host=$env:COMPUTERNAME
      PartOfDomain=(Get-CimInstance Win32_ComputerSystem).PartOfDomain
      Domain=(Get-CimInstance Win32_ComputerSystem).Domain
      OS=(Get-CimInstance Win32_OperatingSystem).Caption
      AutoLogon=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -EA SilentlyContinue).AutoAdminLogon
      LogonUser=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -EA SilentlyContinue).DefaultUserName
    }
  } -ErrorAction Stop
  $r | Format-List
  Remove-PSSession $cs -EA SilentlyContinue
} catch { "PSD FAILED after $([math]::Round($sw.Elapsed.TotalSeconds,1))s : " + $_.Exception.Message.Split([Environment]::NewLine)[0] }
