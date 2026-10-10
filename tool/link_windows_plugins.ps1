<#
.SYNOPSIS
  Pre-creates the Windows plugin links as directory junctions.

.DESCRIPTION
  `flutter build windows` calls `createPluginSymlinks(force: false)`, which
  creates one symlink per Windows plugin under

      windows/flutter/ephemeral/.plugin_symlinks/<plugin>

  and, crucially, skips any link that already exists:

      final Link link = symlinkDirectory.childLink(name);
      if (link.existsSync()) continue;   // flutter_plugins.dart

  On Windows, creating a real symlink needs SeCreateSymbolicLinkPrivilege,
  which a non-administrator only has when Developer Mode is on. Flutter reports
  that as ERROR_PRIVILEGE_NOT_HELD (1314) -> "Building with plugins requires
  symlink support."

  A directory junction needs no privilege at all, and Dart's Link.existsSync()
  reports `true` for one (it reports `false` for a plain directory). So creating
  junctions first makes the loop above skip every link, and CMake resolves
  through junctions exactly as it would through a symlink.

  This is a workaround for a machine without Developer Mode. Enabling Developer
  Mode (`start ms-settings:developers`) is the supported route; this script
  exists so the build is reproducible on a locked-down machine either way.

.NOTES
  Run this AFTER `flutter pub get` and BEFORE `flutter build windows`.
  A `pub get` that changes the plugin list calls createPluginSymlinks(force:
  true), which deletes this directory first.
#>

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pluginsFile = Join-Path $projectRoot '.flutter-plugins-dependencies'
$linkDir = Join-Path $projectRoot 'windows\flutter\ephemeral\.plugin_symlinks'

if (-not (Test-Path $pluginsFile)) {
    throw ".flutter-plugins-dependencies not found. Run 'flutter pub get' first."
}

$deps = Get-Content $pluginsFile -Raw | ConvertFrom-Json
$plugins = @($deps.plugins.windows)

if ($plugins.Count -eq 0) {
    Write-Host 'No Windows plugins declared; nothing to link.'
    exit 0
}

New-Item -ItemType Directory -Path $linkDir -Force | Out-Null

foreach ($p in $plugins) {
    # The JSON stores paths with doubled separators; normalise for mklink.
    $target = $p.path -replace '\\\\+', '\'
    if (-not (Test-Path $target)) {
        throw "Plugin target missing for $($p.name): $target"
    }

    $link = Join-Path $linkDir $p.name

    if (Test-Path $link) {
        Write-Host ("  kept    {0}" -f $p.name)
        continue
    }

    $out = cmd /c "mklink /J `"$link`" `"$target`"" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "mklink failed for $($p.name): $out"
    }
    Write-Host ("  linked  {0} -> {1}" -f $p.name, $target)
}

# Prove CMake's lookup resolves: <link>/windows/CMakeLists.txt where present.
$cmakeReferenced = @('connectivity_plus', 'serious_python_windows', 'jni')
foreach ($name in $cmakeReferenced) {
    $probe = Join-Path $linkDir "$name\windows\CMakeLists.txt"
    if (Test-Path $probe) {
        Write-Host ("  ok      {0} resolves" -f $name)
    } else {
        Write-Host ("  WARN    {0} has no windows/CMakeLists.txt" -f $name)
    }
}
