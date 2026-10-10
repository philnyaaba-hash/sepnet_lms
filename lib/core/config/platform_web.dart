/// Web implementation of [platform_io.dart].
///
/// A browser is none of the native platforms, so every query is false. This
/// file exists so that `AppConfig` can ask platform questions without importing
/// `dart:io`, which does not compile for the web.
library;

/// True on Android.
bool get isAndroid => false;

/// True on iOS.
bool get isIOS => false;

/// True on Windows.
bool get isWindows => false;
