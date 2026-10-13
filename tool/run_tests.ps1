param(
  [string]$Target = ''
)

# Runs the Flutter tests and saves the full output to tool\test_results.txt.
#   All tests:      powershell -ExecutionPolicy Bypass -File .\tool\run_tests.ps1
#   Units only:     powershell -ExecutionPolicy Bypass -File .\tool\run_tests.ps1 -Target test\all_units_smoke_test.dart
# To make the real-Python checks run, set SB_TEST_PYTHON to a working python.exe first,
# for example:  $env:SB_TEST_PYTHON = "C:\Python312\python.exe"

$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Flutter = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } else { 'C:\src\flutter\bin\flutter.bat' }
$Log = Join-Path $ProjectRoot 'tool\test_results.txt'

if (-not (Test-Path $Flutter)) {
  throw "Flutter SDK not found at '$Flutter'. Set FLUTTER_BIN to flutter.bat."
}

$env:Path = "$(Split-Path $Flutter -Parent);$env:Path"

Push-Location $ProjectRoot
try {
  $testArgs = @('test', '--no-pub', '--reporter', 'expanded')
  if ($Target -ne '') { $testArgs += $Target }
  & $Flutter @testArgs 2>&1 | Tee-Object -FilePath $Log
  $code = $LASTEXITCODE
} finally {
  Pop-Location
}

Write-Output ""
Write-Output "Exit code: $code  (0 = all passed)"
Write-Output "Full log saved to: $Log"
exit $code
