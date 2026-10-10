import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:skillbridge_python_lab/core/storage/app_database.dart';
import 'package:skillbridge_python_lab/core/storage/submission_repository.dart';
import 'package:skillbridge_python_lab/features/offline_sync/connectivity_service.dart';
import 'package:skillbridge_python_lab/features/offline_sync/submission_sync_service.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';
import 'package:skillbridge_python_lab/integrations/lms/mock_lms_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const learner = 'learner-1';
  const baseBackoff = Duration(milliseconds: 400);

  late AppDatabase database;
  late SubmissionRepository repository;
  late String dbPath;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    dbPath = p.join(Directory.systemTemp.path,
        'sb_sync_${DateTime.now().microsecondsSinceEpoch}.db');
    // In-process FFI: see app_database.dart for why the isolate-backed factory
    // is not usable inside `testWidgets`.
    database = AppDatabase(factory: databaseFactoryFfiNoIsolate, path: dbPath);
    await database.open();
    repository = SubmissionRepository(database);
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
    String code = 'print("hello")',
    DateTime? createdAt,
  }) =>
      Submission(
        id: id,
        learnerRef: learner,
        exerciseId: 'ex-hello-world',
        exerciseVersion: 1,
        code: code,
        createdAt: createdAt ?? DateTime(2026, 1, 1),
      );

  SubmissionSyncService buildService({
    required MockLmsClient lms,
    ConnectivityService? connectivity,
    int maxAttemptsPerItem = 3,
    List<Duration>? recordedDelays,
  }) =>
      SubmissionSyncService(
        lmsClient: lms,
        submissions: repository,
        connectivity: connectivity ?? FakeConnectivityService(),
        maxAttemptsPerItem: maxAttemptsPerItem,
        baseBackoff: baseBackoff,
        delay: recordedDelays == null
            ? null
            : (duration) async {
                recordedDelays.add(duration);
              },
      );

  group('happy path', () {
    test('an accepted submission leaves the queue and keeps its receipt',
        () async {
      await repository.enqueue(submission());
      final lms = MockLmsClient();
      final service = buildService(lms: lms);

      final report = await service.syncPending(learner);

      expect(report.attempted, 1);
      expect(report.accepted, 1);
      expect(report.failed, 0);
      expect(report.rejected, 0);
      expect(report.authExpired, isFalse);

      final stored = await repository.findById('sub-1');
      expect(stored!.syncState, SubmissionSyncState.accepted);
      expect(stored.attemptCount, 1);
      expect(stored.serverResponseRef, startsWith('SRV-'));
      expect(stored.lastError, isNull);
      expect(await repository.pending(learner), isEmpty);
      expect(await repository.pendingCount(learner), 0);
    });

    test('a second pass after success does no work', () async {
      await repository.enqueue(submission());
      final lms = MockLmsClient();
      final service = buildService(lms: lms);

      await service.syncPending(learner);
      final second = await service.syncPending(learner);

      expect(second.didWork, isFalse);
      expect(lms.gradeCount, 1);
    });
  });

  group('transient failure and backoff', () {
    test('retries with bounded exponential backoff and never discards the item',
        () async {
      await repository.enqueue(submission());
      final delays = <Duration>[];
      final lms = MockLmsClient(failNetworkTimes: 3);
      final service = buildService(
        lms: lms,
        maxAttemptsPerItem: 3,
        recordedDelays: delays,
      );

      final report = await service.syncPending(learner);

      expect(report.attempted, 1);
      expect(report.failed, 1);
      expect(report.accepted, 0);
      expect(report.rejected, 0);

      // Backoff doubles per attempt inside a pass: 1x then 2x base.
      expect(delays, [baseBackoff, baseBackoff * 2]);

      // The submission is still queued (transient `failed`), not thrown away.
      final stored = await repository.findById('sub-1');
      expect(stored, isNotNull);
      expect(stored!.syncState, SubmissionSyncState.failed);
      expect(stored.attemptCount, 3);
      expect(stored.lastError, isNotEmpty);
      expect(await repository.pending(learner), hasLength(1));
      expect(await repository.pendingCount(learner), 1);
    });

    test('succeeds on a later pass once the network recovers', () async {
      await repository.enqueue(submission());
      final lms = MockLmsClient(failNetworkTimes: 1);
      final service = buildService(lms: lms, maxAttemptsPerItem: 1);

      final first = await service.syncPending(learner);
      expect(first.failed, 1);
      expect(await repository.pendingCount(learner), 1);

      final second = await service.syncPending(learner);
      expect(second.accepted, 1);
      expect(await repository.pendingCount(learner), 0);
      expect((await repository.findById('sub-1'))!.syncState,
          SubmissionSyncState.accepted);
    });

    test('the backoff exponent is capped', () async {
      await repository.enqueue(submission());
      final delays = <Duration>[];
      final lms = MockLmsClient(failNetworkTimes: 10);
      final service = buildService(
        lms: lms,
        maxAttemptsPerItem: 9,
        recordedDelays: delays,
      );

      await service.syncPending(learner);

      // Attempts 1..8 wait (attempt 9 exhausts the pass without waiting), with
      // exponents 0..7. _pow2 caps at 2^6 so the tail is clamped at 64.
      expect(delays, [
        baseBackoff * 1,
        baseBackoff * 2,
        baseBackoff * 4,
        baseBackoff * 8,
        baseBackoff * 16,
        baseBackoff * 32,
        baseBackoff * 64,
        baseBackoff * 64,
      ]);
    });
  });

  group('permanent failure', () {
    test('an empty submission is rejected once and not retried', () async {
      await repository.enqueue(submission(code: ''));
      final lms = MockLmsClient();
      final delays = <Duration>[];
      final service = buildService(lms: lms, recordedDelays: delays);

      final report = await service.syncPending(learner);

      expect(report.rejected, 1);
      expect(report.failed, 0);
      expect(delays, isEmpty, reason: 'no backoff for a permanent error');
      expect(lms.gradeCount, 0, reason: 'nothing was graded');

      final stored = await repository.findById('sub-1');
      expect(stored!.syncState, SubmissionSyncState.rejected);
      expect(stored.attemptCount, 1);
      expect(stored.lastError, isNotEmpty);
      expect(await repository.pending(learner), isEmpty);
    });

    test('a rejected verdict is recorded as a terminal rejected state', () async {
      await repository.enqueue(submission(code: 'TODO: finish me'));
      final lms = MockLmsClient();
      final service = buildService(lms: lms);

      final report = await service.syncPending(learner);

      expect(report.rejected, 1);
      final stored = await repository.findById('sub-1');
      expect(stored!.syncState, SubmissionSyncState.rejected);
      expect(stored.serverStatus, 'rejected');
      expect(await repository.pending(learner), isEmpty);
    });
  });

  group('offline', () {
    test('does nothing while offline and leaves the queue untouched', () async {
      await repository.enqueue(submission());
      final lms = MockLmsClient();
      final connectivity = FakeConnectivityService(online: false);
      final service = buildService(lms: lms, connectivity: connectivity);

      final report = await service.syncPending(learner);

      expect(report.offline, isTrue);
      expect(report.attempted, 0);
      expect(lms.gradeCount, 0);

      final stored = await repository.findById('sub-1');
      expect(stored!.syncState, SubmissionSyncState.pending);
      expect(stored.attemptCount, 0);
      expect(await repository.pendingCount(learner), 1);
    });
  });

  group('session expiry', () {
    test('stops the pass and preserves the queue', () async {
      await repository.enqueue(submission(id: 'first'));
      await repository.enqueue(
          submission(id: 'second', createdAt: DateTime(2026, 1, 2)));
      final lms = MockLmsClient(failAuthenticationTimes: 1);
      final service = buildService(lms: lms);

      final report = await service.syncPending(learner);

      expect(report.authExpired, isTrue);
      expect(report.attempted, 1);
      expect(report.accepted, 0);

      final first = await repository.findById('first');
      final second = await repository.findById('second');
      expect(first!.syncState, SubmissionSyncState.failed);
      expect(first.lastError, isNotEmpty);
      expect(second!.syncState, SubmissionSyncState.pending,
          reason: 'the queue must not be flushed by an auth error');
      expect(await repository.pendingCount(learner), 2);
    });
  });

  group('idempotency and duplicate rewards', () {
    test('the same submission id is graded exactly once', () async {
      final lms = MockLmsClient();
      final target = submission();

      final first = await lms.submitSolution(target);
      final second = await lms.submitSolution(target);

      expect(lms.gradeCount, 1);
      expect(first.duplicate, isFalse);
      expect(second.duplicate, isTrue);
      expect(second.pointsAwarded, first.pointsAwarded);

      final progress = await lms.fetchProgress();
      expect(progress.totalPoints, 10, reason: 'never awarded twice');
      expect(progress.completedChallenges, 1);
    });

    test('a retry of an already-accepted submission awards nothing extra',
        () async {
      await repository.enqueue(submission());
      final lms = MockLmsClient();
      final service = buildService(lms: lms);

      await service.syncPending(learner);

      // Force the row back into the queue to model a client-side re-sync bug.
      final stored = await repository.findById('sub-1');
      await repository.update(stored!
          .copyWith(syncState: SubmissionSyncState.pending));

      final report = await service.syncPending(learner);
      expect(report.accepted, 1);

      final progress = await lms.fetchProgress();
      expect(lms.gradeCount, 1, reason: 'the LMS deduplicates by submission id');
      expect(progress.totalPoints, 10);
    });
  });

  group('report', () {
    test('allSettled is true only when every item reached a terminal state',
        () async {
      await repository.enqueue(submission(id: 'ok'));
      await repository.enqueue(
          submission(id: 'bad', code: 'TODO', createdAt: DateTime(2026, 1, 2)));
      final service = buildService(lms: MockLmsClient());

      final report = await service.syncPending(learner);
      expect(report.attempted, 2);
      expect(report.accepted, 1);
      expect(report.rejected, 1);
      expect(report.allSettled, isTrue);
    });
  });
}
