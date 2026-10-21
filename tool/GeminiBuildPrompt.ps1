$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'HHL Stay - Bật Gemini'
$form.Size = New-Object System.Drawing.Size(560, 250)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = 'Dán Gemini API key (nhập sẽ được che):'
$label.Location = New-Object System.Drawing.Point(18, 18)
$label.AutoSize = $true
$form.Controls.Add($label)

$keyBox = New-Object System.Windows.Forms.TextBox
$keyBox.Location = New-Object System.Drawing.Point(20, 48)
$keyBox.Size = New-Object System.Drawing.Size(500, 28)
$keyBox.UseSystemPasswordChar = $true
$form.Controls.Add($keyBox)

$buildButton = New-Object System.Windows.Forms.Button
$buildButton.Text = 'Build và bật Gemini'
$buildButton.Location = New-Object System.Drawing.Point(20, 86)
$buildButton.Size = New-Object System.Drawing.Size(160, 34)
$form.Controls.Add($buildButton)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Key chỉ được dùng để build rồi xóa file tạm.'
$status.Location = New-Object System.Drawing.Point(20, 132)
$status.Size = New-Object System.Drawing.Size(500, 55)
$form.Controls.Add($status)

$buildButton.Add_Click({
  $key = $keyBox.Text
  if ([string]::IsNullOrWhiteSpace($key)) {
    [System.Windows.Forms.MessageBox]::Show('Hãy dán API key trước.') | Out-Null
    return
  }
  $buildButton.Enabled = $false
  $keyBox.Clear()
  $status.Text = 'Đang build web với Gemini. Đợi đến khi hoàn tất...'
  $form.Refresh()
  $defineFile = Join-Path $env:TEMP ('hhl-gemini-' + [guid]::NewGuid().ToString('N') + '.json')
  try {
    @{ GEMINI_API_KEY = $key } | ConvertTo-Json -Compress | Set-Content -LiteralPath $defineFile -Encoding utf8
    $key = $null
    Set-Location 'D:\LapTrinhMobile\nhom_huan_hieu_long'
    & flutter build web --dart-define-from-file="$defineFile"
    if ($LASTEXITCODE -ne 0) { throw "Flutter build thất bại (exit $LASTEXITCODE)." }
    $status.Text = 'Build xong. Gemini đã được cấu hình. Mở localhost:8083/#/ai-chat và tải lại trang.'
    $form.Text = 'HHL Stay - Gemini đã bật'
  } catch {
    $status.Text = 'Build lỗi: ' + $_.Exception.Message
    $buildButton.Enabled = $true
  } finally {
    $key = $null
    if (Test-Path -LiteralPath $defineFile) { Remove-Item -LiteralPath $defineFile -Force }
  }
})

[void]$form.ShowDialog()
