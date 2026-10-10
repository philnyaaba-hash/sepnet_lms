/// Which platform we are running on, without importing `dart:io` in files that
/// must also compile for the web.
///
/// `dart:io` and `dart:ffi` do not exist in a browser, and importing them there
/// is a compile error rather than a runtime one. This shim is swapped for a web
/// implementation via a conditional import, so callers can ask platform
/// questions without ever pulling `dart:io` into the web build.
library;

import 'dart:io' show Platform;

/// True on Android.
bool get isAndroid => Platform.isAndroid;

/// True on iOS.
bool get isIOS => Platform.isIOS;

/// True on Windows.
bool get isWindows => Platform.isWindows;
