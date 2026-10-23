$ErrorActionPreference = 'Stop'
Set-Location 'D:\LapTrinhMobile\nhom_huan_hieu_long'

$secureKey = Read-Host 'Dán API key Gemini từ AI Studio vào đây rồi nhấn Enter' -AsSecureString
$bstr = [IntPtr]::Zero
$defineFile = Join-Path $env:TEMP ('hhl-gemini-' + [guid]::NewGuid().ToString('N') + '.json')
try {
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
  $plainKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  if ([string]::IsNullOrWhiteSpace($plainKey)) { throw 'Key đang trống.' }

  @{ GEMINI_API_KEY = $plainKey } |
    ConvertTo-Json -Compress |
    Set-Content -LiteralPath $defineFile -Encoding utf8
  $plainKey = $null

  Write-Host 'Đang build HHL Stay Web với cấu hình Gemini...'
  & flutter build web --dart-define-from-file="$defineFile" --base-href / --output build/web --pwa-strategy=none
  if ($LASTEXITCODE -ne 0) { throw "Flutter build thất bại (exit $LASTEXITCODE)." }

  # Replace the existing `flutter run` dev server, which was started without
  # the key and would otherwise keep serving an unconfigured app.
  $listeners = Get-NetTCPConnection -LocalPort 8083 -State Listen -ErrorAction SilentlyContinue
  foreach ($listener in $listeners) {
    $process = Get-CimInstance Win32_Process -Filter "ProcessId=$($listener.OwningProcess)" -ErrorAction SilentlyContinue
    if ($process -and $process.CommandLine -match 'flutter_tools\.snapshot.*run.*web-port 8083') {
      Stop-Process -Id $process.ProcessId -Force
    }
  }
  Start-Sleep -Milliseconds 700
  $python = (Get-Command python -ErrorAction Stop).Source
  Start-Process -FilePath $python -ArgumentList @('-m','http.server','8083','--bind','127.0.0.1','--directory',(Join-Path (Get-Location) 'build\web')) -WorkingDirectory (Get-Location) -WindowStyle Hidden | Out-Null
  Start-Sleep -Seconds 2
  $check = Invoke-WebRequest -Uri 'http://127.0.0.1:8083/' -TimeoutSec 8
  if ([int]$check.StatusCode -ne 200) { throw 'Web server không trả về HTTP 200.' }
  Write-Host 'BUILD_OK. Localhost:8083 đã phục vụ bản mới. Mở /#/ai-chat và nhấn Ctrl+Shift+R.' -ForegroundColor Green
} catch {
  Write-Host ('BUILD_ERROR: ' + $_.Exception.Message) -ForegroundColor Red
} finally {
  if ($bstr -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
  if (Test-Path -LiteralPath $defineFile) {
    Remove-Item -LiteralPath $defineFile -Force
  }
  $secureKey = $null
  $plainKey = $null
}

Read-Host 'Nhấn Enter để đóng cửa sổ'
