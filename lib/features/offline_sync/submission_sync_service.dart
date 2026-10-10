// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'package:skillbridge_python_lab/core/storage/submission_repository.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_client.dart';
import 'package:skillbridge_python_lab/integrations/lms/lms_models.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';
import 'connectivity_service.dart';

/// Summary of one synchronization pass, surfaced to the UI.
class SyncReport {
  const SyncReport({
    this.attempted = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.failed = 0,
    this.authExpired = false,
    this.offline = false,
  });

  final int attempted;
  final int accepted;
  final int rejected;
  final int failed;
  final bool authExpired;
  final bool offline;

  bool get didWork => attempted > 0;
  bool get allSettled => attempted == accepted + rejected;

  SyncReport _merge({int? attempted, int? accepted, int? rejected, int? failed}) => SyncReport(
        attempted: attempted ?? this.attempted,
        accepted: accepted ?? this.accepted,
        rejected: rejected ?? this.rejected,
        failed: failed ?? this.failed,
        authExpired: authExpired,
        offline: offline,
      );

  static const offlineReport = SyncReport(offline: true, authExpired: false);
}

/// Drains the durable submission queue to the LMS.
///
/// Guarantees:
///  * Never silently drops a submission. Every item ends in a known state.
///  * Idempotent: retries reuse the same submission id / idempotency key.
///  * Transient failures are retried with bounded exponential backoff; the item
///    stays in the queue as `failed` and is retried on the next pass.
///  * Permanent failures (server 4xx) are recorded as `rejected`.
///  * An expired session stops the pass without discarding anything.
class SubmissionSyncService {
  SubmissionSyncService({
    required LmsClient lmsClient,
    required SubmissionRepository submissions,
    required ConnectivityService connectivity,
    this.maxAttemptsPerItem = 3,
    this.baseBackoff = const Duration(milliseconds: 400),
    Future<void> Function(Duration)? delay,
  })  : _lms = lmsClient,
        _submissions = submissions,
        _connectivity = connectivity,
        _delay = delay ?? Future<void>.delayed;

  final LmsClient _lms;
  final SubmissionRepository _submissions;
  final ConnectivityService _connectivity;
  final int maxAttemptsPerItem;
  final Duration baseBackoff;
  final Future<void> Function(Duration) _delay;

  /// Synchronizes every pending/failed submission for [learnerRef].
  Future<SyncReport> syncPending(String learnerRef) async {
    await _connectivity.refresh();
    if (!_connectivity.isOnline) {
      return SyncReport.offlineReport;
    }

    final queue = await _submissions.pending(learnerRef);
    var report = const SyncReport();

    for (final submission in queue) {
      report = report._merge(attempted: report.attempted + 1);
      final outcome = await _syncOne(submission);

      switch (outcome) {
        case _Outcome.accepted:
          report = report._merge(accepted: report.accepted + 1);
        case _Outcome.rejected:
          report = report._merge(rejected: report.rejected + 1);
        case _Outcome.failed:
          report = report._merge(failed: report.failed + 1);
        case _Outcome.authExpired:
          // Stop early; the session must be renewed before anything else.
          return SyncReport(
            attempted: report.attempted,
            accepted: report.accepted,
            rejected: report.rejected,
            failed: report.failed,
            authExpired: true,
          );
      }
    }
    return report;
  }

  Future<_Outcome> _syncOne(Submission submission) async {
    await _submissions.update(submission.copyWith(syncState: SubmissionSyncState.syncing));

    final wasAttempted = submission.attemptCount;
    var attempt = wasAttempted;
    Object? lastError;

    while (attempt < wasAttempted + maxAttemptsPerItem) {
      attempt++;
      try {
        final receipt = await _lms.submitSolution(submission);
        final accepted = receipt.verdict == GradeVerdict.accepted;
        await _submissions.update(submission.copyWith(
          syncState: accepted ? SubmissionSyncState.accepted : SubmissionSyncState.rejected,
          attemptCount: attempt,
          lastAttemptAt: DateTime.now(),
          serverResponseRef: receipt.serverRef,
          serverStatus: receipt.verdict.name,
          lastError: null,
        ));
        return accepted ? _Outcome.accepted : _Outcome.rejected;
      } on AuthenticationException catch (e) {
        await _submissions.update(submission.copyWith(
          syncState: SubmissionSyncState.failed,
          attemptCount: attempt,
          lastAttemptAt: DateTime.now(),
          lastError: e.userMessage,
        ));
        return _Outcome.authExpired;
      } on NetworkException catch (e) {
        lastError = e;
        // Back off before the next attempt within this pass.
        if (attempt < wasAttempted + maxAttemptsPerItem) {
          await _delay(baseBackoff * _pow2(attempt - wasAttempted - 1));
        }
      } on LmsException catch (e) {
        // Permanent server-side rejection: do not keep retrying.
        await _submissions.update(submission.copyWith(
          syncState: SubmissionSyncState.rejected,
          attemptCount: attempt,
          lastAttemptAt: DateTime.now(),
          serverStatus: 'rejected',
          lastError: e.userMessage,
        ));
        return _Outcome.rejected;
      } on AppException catch (e) {
        lastError = e;
      }
    }

    // Exhausted this pass without success; keep it queued for a later pass.
    await _submissions.update(submission.copyWith(
      syncState: SubmissionSyncState.failed,
      attemptCount: attempt,
      lastAttemptAt: DateTime.now(),
      lastError: lastError?.toString() ?? 'Will retry when the network is available.',
    ));
    return _Outcome.failed;
  }

  static int _pow2(int exponent) {
    var value = 1;
    for (var i = 0; i < exponent && i < 6; i++) {
      value *= 2;
    }
    return value;
  }
}

enum _Outcome { accepted, rejected, failed, authExpired }
