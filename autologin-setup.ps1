param(
  [string]$UserName = "Orange",
  [string]$Password = "Orange@123",
  [string]$Domain = "BWANA",
  [int]$Count = 0
)
$key = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
try {
  Set-ItemProperty -Path $key -Name "AutoAdminLogon" -Value 1 -Type String -Force -ErrorAction Stop
  Set-ItemProperty -Path $key -Name "DefaultUserName" -Value "$Domain\$UserName" -Type String -Force -ErrorAction Stop
  Set-ItemProperty -Path $key -Name "DefaultPassword" -Value $Password -Type String -Force -ErrorAction Stop
  Set-ItemProperty -Path $key -Name "ForceAutoLogon" -Value 1 -Type String -Force -ErrorAction Stop
  Write-Host "PASS: Autologin set for $Domain\$UserName" -ForegroundColor Green
  exit 0
} catch {
  Write-Host "FAILED: Registry access denied. Run as Administrator." -ForegroundColor Red
  exit 1
}
