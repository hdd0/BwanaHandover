Get-CimInstance Win32_Process -Filter "ProcessId=14040" | ForEach-Object {
  "CmdLine: " + $_.CommandLine
  "Path: " + $_.ExecutablePath
}
(Get-CimInstance Win32_Process -Filter "ProcessId=14040").ParentProcessId | ForEach-Object { $pp=$_; "Parent: $pp"; (Get-CimInstance Win32_Process -Filter "ProcessId=$pp").CommandLine }
