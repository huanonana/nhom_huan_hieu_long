$ErrorActionPreference = 'Stop'
Set-Location 'D:\LapTrinhMobile\nhom_huan_hieu_long'

$setup = Get-NetTCPConnection -LocalPort 8099 -State Listen -ErrorAction SilentlyContinue |
  Select-Object -First 1
if (-not $setup) {
  $python = (Get-Command python -ErrorAction Stop).Source
  Start-Process -FilePath $python `
    -ArgumentList @('tool\gemini_local_setup.py') `
    -WorkingDirectory (Get-Location) `
    -WindowStyle Hidden | Out-Null
  Start-Sleep -Seconds 1
}

Start-Process 'http://127.0.0.1:8099/'
