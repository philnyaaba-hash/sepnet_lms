import 'dart:io';

// The private-field assignment is clearer than an initializing formal here.
// ignore_for_file: prefer_initializing_formals

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Owns the single SQLite connection used by the app.
///
/// Tables:
///  * `drafts`      - one row per (learner, exercise): the current saved code.
///  * `submissions` - the durable submission queue + history.
///  * `exercises`   - cached exercise metadata for offline use.
///  * `sync_meta`   - small key/value bookkeeping (last sync, schema info).
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

  static const int _schemaVersion = 1;

  /// Opens (and migrates) the database.
  Future<void> open() async {
    if (_db != null) return;
    final factory = _factory ?? _platformFactory();
    final path = _overridePath ?? p.join(await factory.getDatabasesPath(), 'skillbridge_lab.db');
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) async {
          // Required for reliable foreign-key enforcement in SQLite.
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          final batch = db.batch();
          batch.execute('''
            CREATE TABLE drafts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              learner_ref TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              exercise_version INTEGER NOT NULL,
              code TEXT NOT NULL,
              updated_at INTEGER NOT NULL,
              UNIQUE(learner_ref, exercise_id)
            )
          ''');
          batch.execute('''
            CREATE TABLE submissions (
              submission_id TEXT PRIMARY KEY,
              learner_ref TEXT NOT NULL,
              exercise_id TEXT NOT NULL,
              exercise_version INTEGER NOT NULL,
              code TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              sync_state TEXT NOT NULL,
              attempt_count INTEGER NOT NULL DEFAULT 0,
              last_attempt_at INTEGER,
              server_response_ref TEXT,
              server_status TEXT,
              last_error TEXT
            )
          ''');
          batch.execute(
            'CREATE INDEX idx_submissions_state ON submissions(sync_state)',
          );
          batch.execute('''
            CREATE TABLE exercises (
              exercise_id TEXT PRIMARY KEY,
              lesson_id TEXT,
              title TEXT NOT NULL,
              instructions TEXT NOT NULL,
              objectives TEXT NOT NULL,
              starter_code TEXT NOT NULL,
              requirements TEXT NOT NULL,
              hints TEXT NOT NULL,
              version INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
          batch.execute('''
            CREATE TABLE sync_meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
          await batch.commit(noResult: true);
        },
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Chooses the FFI factory on desktop (and in tests) and the native plugin on
  /// mobile. `sqflite` itself only implements Android/iOS, so desktop builds
  /// and `flutter test` need `sqflite_common_ffi`.
  static DatabaseFactory _platformFactory() {
    if (Platform.isAndroid || Platform.isIOS) {
      return sqflite.databaseFactory;
    }
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
}
