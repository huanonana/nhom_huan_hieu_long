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
  & flutter build web --dart-define-from-file="$defineFile"
  if ($LASTEXITCODE -ne 0) { throw "Flutter build thất bại (exit $LASTEXITCODE)." }
  Write-Host 'BUILD_OK. Mở http://localhost:8083/#/ai-chat rồi nhấn Ctrl+Shift+R.' -ForegroundColor Green
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
