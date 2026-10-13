$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Apk = if ($args.Count -gt 0) { $args[0] } else { Join-Path $ProjectRoot 'outputs\skillbridge-python-lab-debug.apk' }
if (-not [System.IO.Path]::IsPathRooted($Apk)) { $Apk = Join-Path $ProjectRoot $Apk }

if (-not (Test-Path $Apk)) { throw "APK not found: $Apk" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path $Apk))
try {
  $names = @($archive.Entries.FullName)
} finally {
  $archive.Dispose()
}

$checks = [ordered]@{
  'AndroidManifest.xml' = $names -contains 'AndroidManifest.xml'
  'Flutter assets' = (($names -match '(^|/)flutter_assets/').Count -gt 0)
  'Native libraries' = (($names -match '^lib/.+\.so$').Count -gt 0)
  'DEX classes' = (($names -match '^classes.*\.dex$').Count -gt 0)
}
foreach ($check in $checks.GetEnumerator()) {
  Write-Output ("{0}: {1}" -f $check.Key, $(if ($check.Value) { 'PASS' } else { 'FAIL' }))
}

$adb = Get-Command adb -ErrorAction SilentlyContinue
if (-not $adb) {
  $sdk = if ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { 'C:\Users\HP\AppData\Local\Android\Sdk' }
  $candidate = Join-Path $sdk 'platform-tools\adb.exe'
  try {
    if (Test-Path $candidate) { $adb = Get-Command $candidate }
  } catch {
    Write-Output "ADB launch: SKIPPED (Android SDK is not accessible: $sdk)"
  }
}

if ($adb) {
  $devices = & $adb.Source devices
  Write-Output 'ADB devices:'
  $devices | Write-Output
  $online = @($devices | Select-String "`tdevice$")
  if ($online.Count -gt 0) {
    & $adb.Source install -r $Apk
    if ($LASTEXITCODE -ne 0) { throw 'ADB install failed.' }
    & $adb.Source shell monkey -p com.skillbridge.skillbridge_python_lab 1
    if ($LASTEXITCODE -ne 0) { throw 'ADB launch failed.' }
    Write-Output 'ADB launch: PASS'
  } else {
    Write-Output 'ADB launch: SKIPPED (no online device/emulator)'
  }
} else {
  Write-Output 'ADB launch: SKIPPED (adb unavailable or Android SDK inaccessible)'
}

if ($checks.Values -contains $false) { exit 1 }
Write-Output "Static APK smoke test passed: $Apk"
