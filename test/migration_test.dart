import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:skillbridge_python_lab/core/storage/app_database.dart';
import 'package:skillbridge_python_lab/core/storage/draft_repository.dart';
import 'package:skillbridge_python_lab/core/storage/exercise_repository.dart';
import 'package:skillbridge_python_lab/core/storage/schema_migrations.dart';
import 'package:skillbridge_python_lab/core/storage/submission_repository.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';

/// The schema as it shipped in version 1 of this app, kept verbatim so that
/// upgrades are tested against what is actually on a learner's phone rather
/// than against a convenient approximation.
Future<void> _createV1Schema(Database db) async {
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
      'CREATE INDEX idx_submissions_state ON submissions(sync_state)');
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
}

/// A canonical description of a database's *effective* schema: tables, their
/// columns, and every index with the columns it covers.
///
/// Deliberately not compared via `sqlite_master.sql`, because that stores the
/// statement text verbatim — `CREATE INDEX` and `CREATE INDEX IF NOT EXISTS`
/// describe the same index but do not compare equal as strings. What matters
/// for correctness is the shape, not the wording that produced it.
Future<List<String>> _schemaSignature(Database db) async {
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master "
    "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' "
    'ORDER BY name',
  );

  final signature = <String>[];
  for (final table in tables) {
    final tableName = table['name'] as String;
    signature.add('table $tableName');

    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    for (final column in columns) {
      signature.add(
        '  ${column['name']} ${column['type']}'
        ' null=${column['notnull'] == 0 ? 'yes' : 'no'}'
        ' default=${column['dflt_value']}'
        ' pk=${column['pk']}',
      );
    }

    // `index_list` is keyed by table, so indexes are reported per table. Skip
    // the ones SQLite maintains itself (the PRIMARY KEY / UNIQUE surrogates),
    // which are reported with origin 'u'/'pk' and are not ours to compare.
    final indexes = await db.rawQuery('PRAGMA index_list($tableName)');
    for (final index in indexes) {
      final name = index['name'] as String;
      if (index['origin'] != 'c') continue;
      final covered = await db.rawQuery('PRAGMA index_info($name)');
      signature.add(
        'index $name on $tableName '
        'unique=${index['unique'] == 1} '
        'cols=${covered.map((c) => c['name']).join(',')}',
      );
    }
  }
  return signature;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String dbPath;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    dbPath = p.join(
      Directory.systemTemp.path,
      'sb_migrate_${DateTime.now().microsecondsSinceEpoch}.db',
    );
  });

  tearDown(() async {
    try {
      await Directory(dbPath).delete(recursive: true);
    } catch (_) {
      // Best effort: a leftover temp file must never fail the suite.
    }
  });

  /// Opens the v1 database exactly as the old app would have, seeds it with
  /// learner work, and closes it again.
  Future<void> seedV1Database() async {
    final db = await databaseFactoryFfiNoIsolate.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => _createV1Schema(db),
      ),
    );

    final batch = db.batch();
    batch.insert('drafts', {
      'learner_ref': 'learner-1',
      'exercise_id': 'ex-loops',
      'exercise_version': 3,
      'code': 'for i in range(5):\n    print(i)\n',
      'updated_at': DateTime(2026, 2, 1).millisecondsSinceEpoch,
    });
    batch.insert('drafts', {
      'learner_ref': 'learner-1',
      'exercise_id': 'ex-functions',
      'exercise_version': 1,
      'code': 'def greet(name):\n    return "hi " + name\n',
      'updated_at': DateTime(2026, 2, 2).millisecondsSinceEpoch,
    });
    batch.insert('drafts', {
      'learner_ref': 'learner-2',
      'exercise_id': 'ex-loops',
      'exercise_version': 3,
      'code': 'print("someone else")\n',
      'updated_at': DateTime(2026, 2, 3).millisecondsSinceEpoch,
    });
    // One submission in every state the queue can hold, so the migration is
    // exercised against the whole shape of the table.
    for (final entry in {
      'sub-pending': SubmissionSyncState.pending,
      'sub-failed': SubmissionSyncState.failed,
      'sub-syncing': SubmissionSyncState.syncing,
      'sub-accepted': SubmissionSyncState.accepted,
      'sub-rejected': SubmissionSyncState.rejected,
    }.entries) {
      batch.insert('submissions', {
        'submission_id': entry.key,
        'learner_ref': 'learner-1',
        'exercise_id': 'ex-loops',
        'exercise_version': 3,
        'code': 'print(42)\n',
        'created_at': DateTime(2026, 2, 4).millisecondsSinceEpoch,
        'sync_state': entry.value.name,
        'attempt_count': 2,
        'last_attempt_at': DateTime(2026, 2, 5).millisecondsSinceEpoch,
        'server_response_ref': 'SRV-${entry.key}',
        'server_status': 'accepted',
        'last_error': null,
      });
    }
    batch.insert('exercises', {
      'exercise_id': 'ex-loops',
      'lesson_id': 'lesson-3',
      'title': 'Loops',
      'instructions': 'Print 0 to 4.',
      'objectives': 'understand for\u0001use range',
      'starter_code': '',
      'requirements': 'prints five lines',
      'hints': 'range(5)\u0001indent the body',
      'version': 3,
      'updated_at': DateTime(2026, 1, 1).millisecondsSinceEpoch,
    });
    batch.insert('sync_meta', {
      'key': 'last_sync_at',
      'value': '${DateTime(2026, 2, 6).millisecondsSinceEpoch}',
    });
    await batch.commit(noResult: true);
    await db.close();
  }

  group('the migration guard rails', () {
    test('refuses a version bump that has no registered migration', () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1),
      );

      // Pretend someone bumped the version to 3 without writing step 3.
      await expectLater(
        runMigrations(db, from: 1, to: 3),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('No migration registered'), contains('[3]')),
          ),
        ),
      );
      await db.close();
    });

    test('refuses a downgrade rather than corrupting the data', () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1),
      );
      await expectLater(
        runMigrations(db, from: 3, to: 1),
        throwsA(isA<ArgumentError>()),
      );
      await db.close();
    });

    test('is a no-op when already at the target version', () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, _) => _createV1Schema(db)),
      );
      // Must not throw and must not touch the tables.
      await runMigrations(db, from: 1, to: 1);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
      );
      expect(tables.map((t) => t['name']), contains('drafts'));
      await db.close();
    });

    test('every registered step is numbered consecutively from 2', () {
      final versions = kMigrations.map((s) => s.version).toList();
      expect(versions, List.generate(versions.length, (i) => i + 2),
          reason: 'kMigrations must cover 2..$kSchemaVersion with no gaps, '
              'or runMigrations will refuse to open an existing install.');
      expect(AppDatabase.schemaVersion, kSchemaVersion);
    });

    test('a step that throws rolls the whole upgrade back', () async {
      // Learner work in a v1 database.
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, _) => _createV1Schema(db)),
      );
      await db.insert('drafts', {
        'learner_ref': 'learner-1',
        'exercise_id': 'ex-a',
        'exercise_version': 1,
        'code': 'print("precious")',
        'updated_at': 0,
      });
      await db.close();

      var ranSecondStep = false;
      await expectLater(
        databaseFactoryFfiNoIsolate.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 2,
            onUpgrade: (db, from, to) => runMigrations(
              db,
              from: from,
              to: to,
              migrations: [
                MigrationStep(
                  version: 2,
                  description: 'first step succeeds',
                  apply: (db) async {
                    await db.execute(
                      'CREATE INDEX IF NOT EXISTS idx_probe '
                      'ON drafts(learner_ref)',
                    );
                  },
                ),
                MigrationStep(
                  version: 2,
                  description: 'second step fails on purpose',
                  apply: (db) async {
                    ranSecondStep = true;
                    await db.execute('THIS IS NOT SQL');
                  },
                ),
              ],
            ),
          ),
        ),
        throwsA(anything),
      );

      expect(ranSecondStep, isTrue,
          reason: 'the failing step should actually have run');

      // The database must still be usable and still hold the learner's code.
      final reopened = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1),
      );
      final rows = await reopened.query('drafts');
      expect(rows, hasLength(1));
      expect(rows.first['code'], 'print("precious")');

      // And the partial index from the rolled-back step must be gone.
      final indexes = await reopened.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name = 'idx_probe'",
      );
      expect(indexes, isEmpty,
          reason: 'a failed upgrade must leave the database exactly as it '
              'found it, not half-migrated.');
      await reopened.close();
    });
  });

  group('upgrading a real v1 database to $kSchemaVersion', () {
    test('preserves every learner draft, submission and cached exercise',
        () async {
      await seedV1Database();

      final database =
          AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
      await database.open();
      addTearDown(database.close);

      final drafts = DraftRepository(database);
      final submissions = SubmissionRepository(database);
      final exercises = ExerciseRepository(database);

      final mine = await drafts.listFor('learner-1');
      expect(mine.map((d) => d.exerciseId).toSet(),
          {'ex-loops', 'ex-functions'});
      expect(
        mine.firstWhere((d) => d.exerciseId == 'ex-loops').code,
        'for i in range(5):\n    print(i)\n',
      );

      // Other learners' work is untouched.
      expect(await drafts.listFor('learner-2'), hasLength(1));

      // All five queue states survive the rebuild-free upgrade.
      final history = await submissions.listForLearner('learner-1');
      expect(history, hasLength(5));
      expect(
        history.map((s) => s.syncState).toSet(),
        {
          SubmissionSyncState.pending,
          SubmissionSyncState.failed,
          SubmissionSyncState.syncing,
          SubmissionSyncState.accepted,
          SubmissionSyncState.rejected,
        },
      );
      expect(history.firstWhere((s) => s.id == 'sub-accepted').serverResponseRef,
          'SRV-sub-accepted');

      // Exactly the retryable ones are still queued.
      expect(await submissions.pendingCount('learner-1'), 2);

      final cached = await exercises.findById('ex-loops');
      expect(cached, isNotNull);
      expect(cached!.hints, ['range(5)', 'indent the body']);
      expect(cached.objectives, ['understand for', 'use range']);
    });

    test('the queue still behaves after the migration', () async {
      await seedV1Database();

      final database =
          AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
      await database.open();
      addTearDown(database.close);

      final submissions = SubmissionRepository(database);
      // FIFO order must still hold: the v1 rows share a created_at, so add a
      // new one and check it lands last.
      await submissions.enqueue(Submission(
        id: 'sub-new',
        learnerRef: 'learner-1',
        exerciseId: 'ex-loops',
        exerciseVersion: 3,
        code: 'print("new")',
        createdAt: DateTime(2026, 3, 1),
      ));

      final pending = await submissions.pending('learner-1');
      expect(pending.last.id, 'sub-new');

      // And accepting it must still clear it from the queue.
      final loaded = await submissions.findById('sub-new');
      await submissions.update(loaded!.copyWith(
        syncState: SubmissionSyncState.accepted,
        serverResponseRef: 'SRV-new',
        lastError: null,
      ));
      expect(
        (await submissions.findById('sub-new'))!.serverStatus,
        isNull,
      );
      expect(await submissions.pendingCount('learner-1'), 2);
    });

    test('the new indexes are actually created', () async {
      await seedV1Database();

      final database =
          AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
      await database.open();
      addTearDown(database.close);

      final indexNames = await database.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND tbl_name IN ('drafts', 'submissions') ORDER BY name",
      );
      expect(
        indexNames.map((r) => r['name']).toSet(),
        containsAll(<String>{
          'idx_submissions_state',
          'idx_submissions_learner_state',
          'idx_submissions_learner_created',
          'idx_drafts_learner_updated',
        }),
      );
    });

    test('a second open does not re-run the migration', () async {
      await seedV1Database();

      final first =
          AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
      await first.open();
      final before =
          (await first.db.rawQuery('PRAGMA user_version')).first.values.first;
      await first.close();
      expect(before, kSchemaVersion);

      final second =
          AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
      await second.open();
      addTearDown(second.close);
      expect(
        (await second.db.rawQuery('PRAGMA user_version')).first.values.first,
        kSchemaVersion,
      );
      // Still exactly five submissions: nothing was duplicated.
      expect(await second.db.query('submissions'), hasLength(5));
    });
  });

  group('fresh install and upgraded install agree', () {
    test('produce the same effective schema', () async {
      // Path A: a brand new install, straight to the current version.
      final freshPath = '${dbPath}_fresh';
      final fresh = await databaseFactoryFfiNoIsolate.openDatabase(
        freshPath,
        options: OpenDatabaseOptions(
          version: kSchemaVersion,
          onCreate: (db, _) => createLatestSchema(db),
        ),
      );
      final freshSignature = await _schemaSignature(fresh);
      await fresh.close();

      // Path B: an old install walked forward one version at a time.
      await seedV1Database();
      final upgraded = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: kSchemaVersion,
          onCreate: (db, _) => createLatestSchema(db),
          onUpgrade: (db, from, to) => runMigrations(db, from: from, to: to),
        ),
      );
      final upgradedSignature = await _schemaSignature(upgraded);
      await upgraded.close();

      expect(upgradedSignature, equals(freshSignature),
          reason: 'A learner who upgraded must end up with the same schema as '
              'a learner who installed fresh. If these differ, the two paths '
              'have drifted and one of them is wrong.');
      expect(freshSignature, isNotEmpty);
    });
  });

  group('migration helpers', () {
    test('columnExists reports present and absent columns', () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, _) => _createV1Schema(db)),
      );

      expect(await columnExists(db, 'drafts', 'code'), isTrue);
      expect(await columnExists(db, 'drafts', 'learner_ref'), isTrue);
      expect(await columnExists(db, 'drafts', 'not_a_column'), isFalse);
      expect(await columnExists(db, 'not_a_table', 'code'), isFalse);
      await db.close();
    });

    test('rebuildTable adds a constrained column and keeps the data', () async {
      final db = await databaseFactoryFfiNoIsolate.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(version: 1, onCreate: (db, _) => _createV1Schema(db)),
      );
      await db.insert('drafts', {
        'learner_ref': 'learner-1',
        'exercise_id': 'ex-a',
        'exercise_version': 1,
        'code': 'print(1)',
        'updated_at': 42,
      });

      // The hard case SQLite's ALTER TABLE cannot do: add a NOT NULL column
      // with a backfilled value for existing rows.
      await rebuildTable(
        db,
        table: 'drafts',
        newTableSql: '''
          CREATE TABLE drafts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            learner_ref TEXT NOT NULL,
            exercise_id TEXT NOT NULL,
            exercise_version INTEGER NOT NULL,
            code TEXT NOT NULL,
            run_count INTEGER NOT NULL DEFAULT 0,
            updated_at INTEGER NOT NULL,
            UNIQUE(learner_ref, exercise_id)
          )
        ''',
        copy: [
          'id',
          'learner_ref',
          'exercise_id',
          'exercise_version',
          'code',
          'updated_at',
        ],
      );
      await db.execute(
        'CREATE INDEX idx_drafts_learner_updated '
        'ON drafts(learner_ref, updated_at DESC)',
      );

      final rows = await db.query('drafts');
      expect(rows, hasLength(1));
      expect(rows.first['code'], 'print(1)');
      expect(rows.first['run_count'], 0,
          reason: 'the backfill default must be applied to existing rows');

      expect(await columnExists(db, 'drafts', 'run_count'), isTrue);
      expect(
        await db.rawQuery("SELECT name FROM sqlite_master "
            "WHERE type = 'table' AND name = 'drafts_migrating'"),
        isEmpty,
        reason: 'the old table must be dropped, not left behind as clutter',
      );

      // The rebuild drops the old indexes with the old table, so the calling
      // migration has to re-create them; verify it can.
      final indexes = await db.rawQuery("SELECT name FROM sqlite_master "
          "WHERE type = 'index' AND name = 'idx_drafts_learner_updated'");
      expect(indexes, hasLength(1));

      // And the new column is writable, proving it is a real NOT NULL column.
      await db.insert('drafts', {
        'learner_ref': 'learner-1',
        'exercise_id': 'ex-b',
        'exercise_version': 1,
        'code': 'print(2)',
        'run_count': 7,
        'updated_at': 43,
      });
      expect((await db.query('drafts')).length, 2);
      await db.close();
    });
  });
}
