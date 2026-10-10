// The private-field assignment is clearer than an initializing formal here.
// ignore_for_file: prefer_initializing_formals

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_factory_platform.dart';
import 'schema_migrations.dart';

/// Owns the single SQLite connection used by the app.
///
/// Tables:
///  * `drafts`      - one row per (learner, exercise): the current saved code.
///  * `submissions` - the durable submission queue + history.
///  * `exercises`   - cached exercise metadata for offline use.
///  * `sync_meta`   - small key/value bookkeeping (last sync, schema info).
///
/// Schema changes live in `schema_migrations.dart`. This class deliberately
/// keeps no schema SQL of its own beyond delegating to [createLatestSchema],
/// so that a fresh install and an upgraded install cannot drift apart.
///
/// Sensitive material (auth tokens, secrets) is **never** stored here. Those
/// belong in platform secure storage; see `docs/SECURITY_AND_PRIVACY.md`.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory,
        _overridePath = path;

  final DatabaseFactory? _factory;
  final String? _overridePath;

  Database? _db;
  Database get db {
    final database = _db;
    if (database == null) {
      throw StateError('AppDatabase.open() must be awaited before use.');
    }
    return database;
  }

  bool get isOpen => _db != null;

  /// The schema version this build expects. Defined once, in
  /// `schema_migrations.dart`, next to the migrations that produce it.
  static const int schemaVersion = kSchemaVersion;

  /// Opens (and migrates) the database.
  ///
  /// A fresh install runs [createLatestSchema]. An existing database is moved
  /// forward by `runMigrations`, which refuses to open if any schema version in
  /// between has no registered migration — so a version bump without a
  /// migration fails here instead of losing a learner's drafts.
  Future<void> open() async {
    if (_db != null) return;
    final factory = _factory ?? _platformFactory();
    final path = _overridePath ?? p.join(await factory.getDatabasesPath(), 'skillbridge_lab.db');
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          // Required for reliable foreign-key enforcement in SQLite.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) => createLatestSchema(db),
        onUpgrade: (db, oldVersion, newVersion) => runMigrations(
          db,
          from: oldVersion,
          to: newVersion,
        ),
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Chooses the SQLite implementation for the current platform.
  ///
  /// Android/iOS use the native `sqflite` plugin, desktop and `flutter test`
  /// use `sqflite_common_ffi`, and the web build gets `sqflite_web`. The choice
  /// lives behind a conditional import so that the FFI package is never
  /// compiled into a browser build. See `database_factory_io.dart`.
  static DatabaseFactory _platformFactory() => platformDatabaseFactory();
}
