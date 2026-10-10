/// Platform-specific choice of SQLite implementation.
///
/// `sqflite` only ships an Android/iOS plugin. Desktop and `flutter test` need
/// `sqflite_common_ffi`, which loads SQLite through `dart:ffi` — a library that
/// does not exist in a browser. Pointing the build at a conditional export
/// means the web build never compiles the FFI package at all; `sqflite`
/// federates to `sqflite_web` on its own there.
///
/// Both implementations export the same two names, so callers import this file
/// and use them without knowing which one was selected.
library;

export 'database_factory_io_impl.dart'
    if (dart.library.html) 'database_factory_web.dart';
