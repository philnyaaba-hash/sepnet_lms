/// SQLite for Android, iOS, Windows, macOS, Linux and `flutter test`.
///
/// See `database_factory_platform.dart` for why this sits behind a conditional
/// export.
library;

import 'dart:io' show Platform;

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

export 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactoryFfiNoIsolate;

/// Picks the SQLite implementation for the current platform.
///
/// Android and iOS use the native `sqflite` plugin. Everything else uses
/// `sqflite_common_ffi`, because `sqflite` itself only implements those two
/// mobile platforms — without this, desktop builds and `flutter test` would
/// have no working database.
DatabaseFactory platformDatabaseFactory() {
  if (Platform.isAndroid || Platform.isIOS) {
    return sqflite.databaseFactory;
  }
  sqfliteFfiInit();
  return databaseFactoryFfi;
}
