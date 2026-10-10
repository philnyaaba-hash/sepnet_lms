/// Resolves to the native or web platform shim depending on the build target.
///
/// See `platform_io.dart` for why this indirection exists.
library;

export 'platform_io.dart' if (dart.library.html) 'platform_web.dart';
