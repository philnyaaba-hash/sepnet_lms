$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Flutter = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } else { 'C:\src\flutter\bin\flutter.bat' }
$AndroidSdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { 'C:\Users\HP\AppData\Local\Android\Sdk' }
$Output = Join-Path $ProjectRoot 'outputs\skillbridge-python-lab-debug.apk'

if (-not (Test-Path $Flutter)) {
  throw "Flutter SDK not found at '$Flutter'. Set FLUTTER_BIN to flutter.bat."
}

try {
  $sdkAccessible = Test-Path $AndroidSdk
} catch {
  throw "Android SDK exists but is not accessible to this user: '$AndroidSdk'. Grant read/execute access or set ANDROID_SDK_ROOT to an accessible SDK."
}
if (-not $sdkAccessible) {
  throw "Android SDK not found at '$AndroidSdk'. Set ANDROID_SDK_ROOT to an accessible SDK."
}

$env:FLUTTER_ROOT = Split-Path (Split-Path $Flutter -Parent) -Parent
$env:ANDROID_HOME = $AndroidSdk
$env:ANDROID_SDK_ROOT = $AndroidSdk
$env:PATH = "$(Split-Path $Flutter -Parent);$env:PATH"

New-Item -ItemType Directory -Force -Path (Split-Path $Output -Parent) | Out-Null
Push-Location $ProjectRoot
try {
  & $Flutter build apk --debug --no-pub
  if ($LASTEXITCODE -ne 0) { throw "Flutter build failed with exit code $LASTEXITCODE." }
  $Built = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
  if (-not (Test-Path $Built)) { throw "Flutter reported success but no APK was found at '$Built'." }
  Copy-Item $Built $Output -Force
  Write-Output "APK: $Output"
  Get-Item $Output | Select-Object FullName, Length, LastWriteTime
} finally {
  Pop-Location
}
