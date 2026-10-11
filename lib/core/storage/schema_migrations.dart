// Versioned schema migrations for `AppDatabase`.
//
// Why this file exists
// -------------------
// `AppDatabase` is offline-first: it holds a learner's drafts and the durable
// submission queue. If a schema bump ever discards that, the work is gone
// silently — the learner was probably offline and will not know to re-do it.
// Before this file existed there was an `onCreate` and no `onUpgrade`, so the
// first version bump would have done exactly that. See
// `docs/KNOWN_LIMITATIONS.md` (migrations).
//
// The rules this file enforces
// ---------------------------
//  1. **One source of truth for the latest shape.** [createLatestSchema] is
//     called by `onCreate`, and the same SQL constants are reused by the
//     migrations. A fresh install and an upgraded install therefore converge
//     *by construction* rather than by discipline, and a test asserts it.
//  2. **Every version bump needs a registered step.** [runMigrations] refuses
//     to run if any version between `from` and `to` has no step, so bumping
//     [kSchemaVersion] without writing the migration fails loudly at open time
//     instead of quietly corrupting an install.
//  3. **Steps are additive and re-runnable.** Each step only widens the schema.
//     Index statements use `IF NOT EXISTS` so a step that has been applied
//     before (for example after a user restores a device backup taken
//     mid-migration) cannot fail.
//
// Transactions: sqflite runs `onCreate` / `onUpgrade` / `onDowngrade` inside a
// transaction it manages, so these steps do not open their own. A step that
// throws therefore rolls the whole upgrade back and leaves the database on the
// old version, which is the behaviour we want.
//
// Foreign keys: none of our tables declare one today. The first future schema
// that adds a foreign key **must** also turn `PRAGMA foreign_keys` off for the
// duration of the upgrade, because SQLite cannot disable foreign keys inside a
// transaction and refuses to drop/recreate a parent table while they are
// enforced. That is a known constraint of the rebuild pattern in
// [rebuildTable], not an oversight.

import 'package:sqflite/sqflite.dart';

/// The schema version this build expects.
///
/// Bumping this is only safe together with a new entry in [kMigrations].
/// `runMigrations` treats the two getting out of step as a hard error.
const int kSchemaVersion = 3;

// ---------------------------------------------------------------------------
// SQL for the latest schema.
//
// These constants are shared by `createLatestSchema` (used by `onCreate`) and
// by the migrations, so the two paths cannot drift apart.
// ---------------------------------------------------------------------------

const String _createDraftsTable = '''
  CREATE TABLE drafts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    learner_ref TEXT NOT NULL,
    exercise_id TEXT NOT NULL,
    exercise_version INTEGER NOT NULL,
    code TEXT NOT NULL,
    updated_at INTEGER NOT NULL,
    UNIQUE(learner_ref, exercise_id)
  )
''';

const String _createSubmissionsTable = '''
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
''';

const String _createExercisesTable = '''
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
    updated_at INTEGER NOT NULL,
    lesson TEXT
  )
''';

// `lesson` is deliberately declared **last**, not next to the other content
// columns. SQLite's `ALTER TABLE ADD COLUMN` always appends, so this is the
// only ordering under which a fresh install and an upgraded install produce
// byte-identical column orders. `test/migration_test.dart` asserts that
// convergence, and it is what keeps the two paths from drifting.

const String _createSyncMetaTable = '''
  CREATE TABLE sync_meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
''';

/// Backs `SubmissionRepository.listForLearner(state:)` and the sync service's
/// "what is left to send" count. `sync_state` is the second column, so this
/// does **not** replace `indexSubmissionsState` — an index on
/// `(learner_ref, sync_state)` cannot answer a query filtering on
/// `sync_state` alone.
const String indexSubmissionsState = 'CREATE INDEX IF NOT EXISTS '
    'idx_submissions_state ON submissions(sync_state)';

/// Serves `SubmissionRepository.pending()` and `pendingCount()`, which both
/// filter on `learner_ref` and `sync_state` together and are the queries that
/// run on every app resume.
const String indexSubmissionsLearnerState = 'CREATE INDEX IF NOT EXISTS '
    'idx_submissions_learner_state ON submissions(learner_ref, sync_state)';

/// Serves `SubmissionRepository.listForLearner`, which orders by
/// `created_at DESC` for one learner.
const String indexSubmissionsLearnerCreated = 'CREATE INDEX IF NOT EXISTS '
    'idx_submissions_learner_created ON submissions(learner_ref, created_at DESC)';

/// Serves `DraftRepository.listFor`, the "continue where you left off" list:
/// one learner's drafts, newest first.
const String indexDraftsLearnerUpdated = 'CREATE INDEX IF NOT EXISTS '
    'idx_drafts_learner_updated ON drafts(learner_ref, updated_at DESC)';

const List<String> _allIndexes = [
  indexSubmissionsState,
  indexSubmissionsLearnerState,
  indexSubmissionsLearnerCreated,
  indexDraftsLearnerUpdated,
];

/// Creates every table and index of the **current** [kSchemaVersion].
///
/// Called by `onCreate` for a fresh install. Do not call this to "fix" an
/// existing database; that is what [runMigrations] is for.
Future<void> createLatestSchema(DatabaseExecutor db) async {
  final batch = db.batch();
  batch.execute(_createDraftsTable);
  batch.execute(_createSubmissionsTable);
  batch.execute(_createExercisesTable);
  batch.execute(_createSyncMetaTable);
  for (final statement in _allIndexes) {
    batch.execute(statement);
  }
  await batch.commit(noResult: true);
}

// ---------------------------------------------------------------------------
// Migrations.
// ---------------------------------------------------------------------------

/// One versioned, additive schema change.
///
/// A step must be safe to run against a database that is already at its own
/// version's shape — [runMigrations] will not do that, but the `IF NOT EXISTS`
/// habit keeps a restored backup or a hand-repaired database from breaking.
class MigrationStep {
  const MigrationStep({
    required this.version,
    required this.description,
    required this.apply,
  });

  /// The schema version this step produces. Must be unique and ascending.
  final int version;

  /// One line explaining what changed, for `docs` and for anyone reading a
  /// stack trace years later.
  final String description;

  final Future<void> Function(DatabaseExecutor db) apply;
}

/// Every migration this app knows how to run, oldest first.
const List<MigrationStep> kMigrations = [
  MigrationStep(
    version: 2,
    description:
        'Add composite indexes for the submission queue and the draft list.',
    apply: _migration2Indexes,
  ),
  MigrationStep(
    version: 3,
    description:
        'Add the teaching `lesson` column to exercises so lessons are cached '
        'for offline use.',
    apply: _migration3Lesson,
  ),
];

Future<void> _migration2Indexes(DatabaseExecutor db) async {
  // Additive only, and each statement is idempotent. The existing single-column
  // `idx_submissions_state` is deliberately kept: it is the only index that can
  // serve a `sync_state`-only filter.
  for (final statement in const [
    indexDraftsLearnerUpdated,
    indexSubmissionsLearnerState,
    indexSubmissionsLearnerCreated,
  ]) {
    await db.execute(statement);
  }
}

Future<void> _migration3Lesson(DatabaseExecutor db) async {
  // A plain nullable ADD COLUMN: SQLite supports it, no rebuild is needed, and
  // existing rows get NULL which every reader treats as "no lesson yet".
  if (!await columnExists(db, 'exercises', 'lesson')) {
    await db.execute('ALTER TABLE exercises ADD COLUMN lesson TEXT');
  }
}

/// Applies every step needed to move a database from [from] to [to].
///
/// Throws [StateError] when a version in between has no registered step, which
/// is the guard that stops `kSchemaVersion` being bumped without the migration
/// to match.
Future<void> runMigrations(
  DatabaseExecutor db, {
  required int from,
  required int to,
  List<MigrationStep> migrations = kMigrations,
}) async {
  if (from == to) return;
  if (from > to) {
    throw ArgumentError.value(
      from,
      'from',
      'Downgrading from schema $from to $to is not supported. Ship a rollback '
      'step or clear the local database.',
    );
  }
  if (from < 1) {
    throw ArgumentError.value(
      from,
      'from',
      'Schema versions start at 1.',
    );
  }

  final byVersion = {for (final step in migrations) step.version: step};

  final missing = <int>[
    for (var v = from + 1; v <= to; v++)
      if (!byVersion.containsKey(v)) v,
  ];
  if (missing.isNotEmpty) {
    throw StateError(
      'No migration registered for schema version(s) $missing. '
      'AppDatabase is at $to but only knows how to migrate from $from. '
      'Add a MigrationStep for each to kMigrations (see schema_migrations.dart).',
    );
  }

  for (var v = from + 1; v <= to; v++) {
    await byVersion[v]!.apply(db);
  }
}

// ---------------------------------------------------------------------------
// Helpers for the migrations that need more than `CREATE INDEX`.
// ---------------------------------------------------------------------------

/// Whether [column] exists on [table].
///
/// SQLite has no `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, so a migration
/// that adds a column has to ask first. Cheap: it reads one system table.
Future<bool> columnExists(
  DatabaseExecutor db,
  String table,
  String column,
) async {
  // `table_info` returns one row per column; no rows means no such table,
  // which we report as "the column is absent" so the caller fails on the
  // CREATE rather than silently succeeding.
  final rows = await db.rawQuery('PRAGMA table_info($table)');
  return rows.any((row) => row['name'] == column);
}

/// Rebuilds [table] into the shape declared by [newTableSql], copying the
/// columns named in [copy] (a `new_column = old_column` list).
///
/// SQLite's `ALTER TABLE` can only add a column, drop a column (3.35+), or
/// rename. It cannot change a type, add a `NOT NULL` without a default, or add
/// a constraint — so those changes use the documented rebuild dance:
///
///   1. rename the old table aside,
///   2. create the new one,
///   3. `INSERT INTO ... SELECT` the data across,
///   4. drop the old one.
///
/// Dropping the renamed table drops its indexes with it, so re-create them
/// afterwards in the calling migration.
///
/// This is deliberately *not* used by any shipped migration yet — version 2 is
/// a safe additive change — but it is implemented and covered by
/// `test/migration_test.dart` so the hard path is proven before it is needed,
/// not discovered during a real upgrade on a learner's phone.
Future<void> rebuildTable(
  DatabaseExecutor db, {
  required String table,
  required String newTableSql,
  required List<String> copy,
}) async {
  final backup = '${table}_migrating';
  await db.execute('ALTER TABLE $table RENAME TO $backup');
  await db.execute(newTableSql);
  await db.execute(
    'INSERT INTO $table (${copy.join(', ')}) '
    'SELECT ${copy.join(', ')} FROM $backup',
  );
  await db.execute('DROP TABLE $backup');
}
