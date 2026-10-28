Get-WmiObject Win32_Process -Filter "Name='vmwp.exe'" | Select-Object ProcessId, CommandLine | Format-List
