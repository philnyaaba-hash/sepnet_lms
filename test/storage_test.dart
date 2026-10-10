import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:skillbridge_python_lab/core/storage/app_database.dart';
import 'package:skillbridge_python_lab/core/storage/draft_repository.dart';
import 'package:skillbridge_python_lab/core/storage/exercise_repository.dart';
import 'package:skillbridge_python_lab/core/storage/submission_repository.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DraftRepository drafts;
  late SubmissionRepository submissions;
  late ExerciseRepository exercises;
  late String dbPath;

  const learner = 'learner-1';
  const otherLearner = 'learner-2';

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dbPath = p.join(Directory.systemTemp.path,
        'sb_storage_${DateTime.now().microsecondsSinceEpoch}.db');
    // In-process FFI: see app_database.dart for why the isolate-backed factory
    // is not usable inside `testWidgets`.
    database = AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
    await database.open();
    drafts = DraftRepository(database);
    submissions = SubmissionRepository(database);
    exercises = ExerciseRepository(database);
  });

  tearDown(() async {
    await database.close();
    try {
      await Directory(dbPath).delete(recursive: true);
    } catch (_) {
      // Best effort: a leftover temp file must never fail the suite.
    }
  });

  Submission submission({
    String id = 'sub-1',
    String exerciseId = 'ex-hello-world',
    SubmissionSyncState state = SubmissionSyncState.pending,
    DateTime? createdAt,
    int attemptCount = 0,
    String? code = 'print("hi")',
  }) =>
      Submission(
        id: id,
        learnerRef: learner,
        exerciseId: exerciseId,
        exerciseVersion: 1,
        code: code!,
        createdAt: createdAt ?? DateTime.now(),
        syncState: state,
        attemptCount: attemptCount,
      );

  group('schema', () {
    test('opens and exposes a usable connection', () async {
      expect(database.isOpen, isTrue);
      expect(() => database.db, returnsNormally);
    });

    test('a second open() on an already-open database is a no-op', () async {
      await database.open();
      expect(database.isOpen, isTrue);
    });
  });

  group('DraftRepository', () {
    test('saves and reads back a draft', () async {
      final when = DateTime(2026, 1, 2, 3, 4, 5);
      await drafts.save(
        learnerRef: learner,
        exerciseId: 'ex-a',
        exerciseVersion: 3,
        code: 'print(1)',
        updatedAt: when,
      );

      final loaded = await drafts.find(learner, 'ex-a');
      expect(loaded, isNotNull);
      expect(loaded!.code, 'print(1)');
      expect(loaded.exerciseId, 'ex-a');
      expect(loaded.exerciseVersion, 3);
      expect(loaded.updatedAt.millisecondsSinceEpoch, when.millisecondsSinceEpoch);
    });

    test('saving the same (learner, exercise) again replaces the row', () async {
      await drafts.save(
          learnerRef: learner, exerciseId: 'ex-a', exerciseVersion: 1, code: 'a');
      await drafts.save(
          learnerRef: learner, exerciseId: 'ex-a', exerciseVersion: 1, code: 'b');

      final rows = await drafts.listFor(learner, limit: 100);
      expect(rows, hasLength(1));
      expect(rows.first.code, 'b');
    });

    test('returns null for an unknown draft', () async {
      expect(await drafts.find(learner, 'nope'), isNull);
    });

    test('keeps learners isolated', () async {
      await drafts.save(
          learnerRef: learner, exerciseId: 'ex-a', exerciseVersion: 1, code: 'mine');
      await drafts.save(
          learnerRef: otherLearner,
          exerciseId: 'ex-a',
          exerciseVersion: 1,
          code: 'theirs');

      expect((await drafts.find(learner, 'ex-a'))!.code, 'mine');
      expect((await drafts.find(otherLearner, 'ex-a'))!.code, 'theirs');
      expect(await drafts.listFor(learner), hasLength(1));
    });

    test('lists drafts newest first', () async {
      await drafts.save(
          learnerRef: learner,
          exerciseId: 'older',
          exerciseVersion: 1,
          code: '1',
          updatedAt: DateTime(2026, 1, 1));
      await drafts.save(
          learnerRef: learner,
          exerciseId: 'newer',
          exerciseVersion: 1,
          code: '2',
          updatedAt: DateTime(2026, 6, 1));

      final rows = await drafts.listFor(learner);
      expect(rows.first.exerciseId, 'newer');
      expect(rows.last.exerciseId, 'older');
    });

    test('deleteAllFor removes only that learner (privacy control)', () async {
      await drafts.save(
          learnerRef: learner, exerciseId: 'ex-a', exerciseVersion: 1, code: 'x');
      await drafts.save(
          learnerRef: otherLearner, exerciseId: 'ex-a', exerciseVersion: 1, code: 'y');

      await drafts.deleteAllFor(learner);

      expect(await drafts.listFor(learner), isEmpty);
      expect(await drafts.listFor(otherLearner), hasLength(1));
    });
  });

  group('SubmissionRepository', () {
    test('persists every field through a round trip', () async {
      final created = DateTime(2025, 11, 30, 12, 0);
      final lastAttempt = DateTime(2025, 12, 1, 8, 30);
      final original = Submission(
        id: 'uuid-full',
        learnerRef: learner,
        exerciseId: 'ex-loops',
        exerciseVersion: 7,
        code: 'for i in range(5):\n    print(i)\n',
        createdAt: created,
        syncState: SubmissionSyncState.failed,
        attemptCount: 3,
        lastAttemptAt: lastAttempt,
        serverResponseRef: 'SRV-1',
        serverStatus: 'needs_work',
        lastError: 'temporary',
      );

      expect(await submissions.enqueue(original), isTrue);
      final loaded = await submissions.findById('uuid-full');

      expect(loaded, isNotNull);
      expect(loaded!.id, original.id);
      expect(loaded.learnerRef, learner);
      expect(loaded.exerciseId, 'ex-loops');
      expect(loaded.exerciseVersion, 7);
      expect(loaded.code, original.code);
      expect(loaded.syncState, SubmissionSyncState.failed);
      expect(loaded.attemptCount, 3);
      expect(loaded.serverResponseRef, 'SRV-1');
      expect(loaded.serverStatus, 'needs_work');
      expect(loaded.lastError, 'temporary');
      expect(loaded.createdAt.millisecondsSinceEpoch,
          created.millisecondsSinceEpoch);
      expect(loaded.lastAttemptAt!.millisecondsSinceEpoch,
          lastAttempt.millisecondsSinceEpoch);
    });

    test('enqueue refuses a duplicate submission id', () async {
      expect(await submissions.enqueue(submission()), isTrue);
      expect(await submissions.enqueue(submission()), isFalse);

      final rows = await submissions.listForLearner(learner);
      expect(rows, hasLength(1));
    });

    test('pending() returns pending and failed items oldest first', () async {
      await submissions.enqueue(
          submission(id: 'a', createdAt: DateTime(2026, 1, 3)));
      await submissions.enqueue(
          submission(id: 'b', createdAt: DateTime(2026, 1, 1)));
      await submissions.enqueue(
          submission(id: 'c', createdAt: DateTime(2026, 1, 2)));
      await submissions.enqueue(submission(
          id: 'done', createdAt: DateTime(2026, 1, 4),
          state: SubmissionSyncState.accepted));
      await submissions.enqueue(submission(
          id: 'rej', createdAt: DateTime(2026, 1, 5),
          state: SubmissionSyncState.rejected));

      final pending = await submissions.pending(learner);
      expect(pending.map((s) => s.id).toList(), ['b', 'c', 'a']);
    });

    test('pending() includes items left in the transient failed state', () async {
      await submissions.enqueue(
          submission(id: 'flaky', state: SubmissionSyncState.failed));
      expect(await submissions.pending(learner), hasLength(1));
    });

    test('pendingCount matches the queue', () async {
      expect(await submissions.pendingCount(learner), 0);

      await submissions.enqueue(submission(id: 'p1'));
      await submissions.enqueue(submission(id: 'p2'));
      await submissions.enqueue(
          submission(id: 'ok', state: SubmissionSyncState.accepted));

      expect(await submissions.pendingCount(learner), 2);
      expect(await submissions.pendingCount(otherLearner), 0);
    });

    test('update persists state transitions', () async {
      await submissions.enqueue(submission(id: 's1'));
      final loaded = await submissions.findById('s1');

      await submissions.update(loaded!.copyWith(
        syncState: SubmissionSyncState.accepted,
        attemptCount: 1,
        serverResponseRef: 'SRV-x',
        lastError: null,
      ));

      final updated = await submissions.findById('s1');
      expect(updated!.syncState, SubmissionSyncState.accepted);
      expect(updated.attemptCount, 1);
      expect(updated.serverResponseRef, 'SRV-x');
      expect(await submissions.pending(learner), isEmpty);
      expect(await submissions.pendingCount(learner), 0);
    });

    test('listForLearner can filter by state', () async {
      await submissions.enqueue(submission(id: 'p'));
      await submissions.enqueue(
          submission(id: 'a', state: SubmissionSyncState.accepted));

      final accepted = await submissions.listForLearner(learner,
          state: SubmissionSyncState.accepted);
      expect(accepted.map((s) => s.id), ['a']);
    });

    test('deleteAllFor clears the queue for one learner only', () async {
      await submissions.enqueue(submission(id: 'mine'));

      // Add an unrelated learner's row directly.
      await database.db.insert(
        'submissions',
        Submission(
          id: 'other',
          learnerRef: otherLearner,
          exerciseId: 'ex',
          exerciseVersion: 1,
          code: 'x',
          createdAt: DateTime(2026, 1, 1),
        ).toDbMap(),
      );

      await submissions.deleteAllFor(learner);

      expect(await submissions.listForLearner(learner), isEmpty);
      expect(await submissions.listForLearner(otherLearner), hasLength(1));
    });

    test('unknown id finds nothing', () async {
      expect(await submissions.findById('missing'), isNull);
    });
  });

  group('SubmissionSyncState', () {
    test('classifies terminal and retryable states', () {
      expect(SubmissionSyncState.accepted.isTerminal, isTrue);
      expect(SubmissionSyncState.rejected.isTerminal, isTrue);
      expect(SubmissionSyncState.pending.isTerminal, isFalse);
      expect(SubmissionSyncState.failed.isTerminal, isFalse);
      expect(SubmissionSyncState.syncing.isTerminal, isFalse);

      expect(SubmissionSyncState.pending.isRetryable, isTrue);
      expect(SubmissionSyncState.failed.isRetryable, isTrue);
      expect(SubmissionSyncState.accepted.isRetryable, isFalse);
      expect(SubmissionSyncState.rejected.isRetryable, isFalse);
    });

    test('fromName falls back to pending', () {
      expect(SubmissionSyncState.fromName('accepted'), SubmissionSyncState.accepted);
      expect(SubmissionSyncState.fromName('nonsense'), SubmissionSyncState.pending);
    });
  });

  group('ExerciseRepository', () {
    test('upserts and reads exercises for offline use', () async {
      const exercise = Exercise(
        id: 'ex-cache',
        lessonId: 'lesson-1',
        title: 'Cached',
        instructions: 'Do the thing.',
        objectives: ['o1'],
        requirements: ['r1'],
        starterCode: 'x = 1\n',
        hints: ['h1'],
        version: 2,
      );

      await exercises.upsertAll(const [exercise]);
      final all = await exercises.listAll();
      expect(all, hasLength(1));
      expect(all.first.id, 'ex-cache');
      expect(all.first.title, 'Cached');
      expect(all.first.hints, ['h1']);
    });

    test('re-upserting the same id does not duplicate rows', () async {
      const exercise = Exercise(
        id: 'ex-cache',
        lessonId: 'lesson-1',
        title: 'Cached',
        instructions: 'Do the thing.',
        objectives: [],
        requirements: [],
        starterCode: '',
        hints: [],
        version: 1,
      );
      await exercises.upsertAll(const [exercise]);
      await exercises.upsertAll(const [exercise]);
      expect(await exercises.listAll(), hasLength(1));
    });
  });
}
