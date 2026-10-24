$ErrorActionPreference = 'Stop'

if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  throw 'Firebase CLI is required. Install it with npm install --global firebase-tools.'
}

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Java is not on PATH and Flutter is unavailable to locate Android Studio JBR.'
  }

  $doctorOutput = (& flutter doctor -v 2>&1 | Out-String)
  if ($doctorOutput -match '(?m)^.*Java binary at:\s*(.+)$') {
    $javaBinary = $Matches[1].Trim()
    if (-not [IO.Path]::IsPathRooted($javaBinary)) {
      $javaBinary = Join-Path (Get-Location) $javaBinary
    }
    $javaHome = Split-Path (Split-Path $javaBinary -Parent) -Parent
    $javaExecutable = Join-Path $javaHome 'bin\java.exe'
    if (-not (Test-Path -LiteralPath $javaExecutable)) {
      throw "Flutter reported a Java location that does not exist: $javaExecutable"
    }
    $env:JAVA_HOME = $javaHome
    $env:PATH = "$javaHome\bin;$env:PATH"
  } else {
    throw 'Java was not found. Install a JDK or configure Android Studio so Flutter can find its bundled JBR.'
  }
}

firebase emulators:exec --only auth,firestore --project demo-hhl-stay-rules `
  'npm --prefix tool/firestore-rules-tests test'
exit $LASTEXITCODE
