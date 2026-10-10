/// SQLite for the web.
///
/// See `database_factory_platform.dart` for why this sits behind a conditional
/// export.
library;

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Picks the SQLite implementation for the current platform.
///
/// A browser has no `dart:ffi`, so the native and desktop paths are both
/// unavailable. `sqflite` itself does not federate to any web implementation,
/// so this uses `sqflite_common_ffi_web`: the same SQLite engine compiled to
/// wasm and driven from a shared worker, with state persisted to IndexedDB.
///
/// The wasm binary and worker must be present in `web/`. `dart run
/// sqflite_common_ffi_web:setup` installs them; see `docs/BUILD_AND_RELEASE.md`.
DatabaseFactory platformDatabaseFactory() {
  return databaseFactoryFfiWeb;
}

/// Present only so that both platform files export the same names.
///
/// `sqflite_common_ffi_web` runs SQLite in a shared worker rather than a Dart
/// isolate, so there is no in-process variant to choose here, and no test
/// harness that needs one. Naming the mistake beats silently returning a
/// factory that would behave differently from the one tests rely on.
DatabaseFactory get databaseFactoryFfiNoIsolate => throw UnsupportedError(
      'databaseFactoryFfiNoIsolate has no web equivalent: '
      'sqflite_common_ffi_web runs SQLite in a shared worker, and web tests do '
      'not use the fake-async harness that makes the in-process factory '
      'necessary on native.',
    );
