/// Lifecycle of a submission in the durable offline queue.
///
/// Transitions:
///   pending -> syncing -> accepted | rejected
///                     \-> failed (retryable) -> syncing ...
///
/// `accepted` and `rejected` are *terminal*: the server has made a trusted
/// decision. `failed` is transient and will be retried with backoff.
enum SubmissionSyncState {
  pending,
  syncing,
  accepted,
  rejected,
  failed;

  static SubmissionSyncState fromName(String name) =>
      SubmissionSyncState.values.firstWhere(
        (e) => e.name == name,
        orElse: () => SubmissionSyncState.pending,
      );

  bool get isTerminal =>
      this == SubmissionSyncState.accepted || this == SubmissionSyncState.rejected;

  bool get isRetryable => this == SubmissionSyncState.pending || this == SubmissionSyncState.failed;
}

/// A learner's attempt at an exercise, persisted locally before any network
/// call. The client-generated [id] doubles as the idempotency key so retries
/// never create duplicate submissions or duplicate rewards.
class Submission {
  const Submission({
    required this.id,
    required this.learnerRef,
    required this.exerciseId,
    required this.exerciseVersion,
    required this.code,
    required this.createdAt,
    this.syncState = SubmissionSyncState.pending,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.serverResponseRef,
    this.serverStatus,
    this.lastError,
  });

  final String id;
  final String learnerRef;
  final String exerciseId;
  final int exerciseVersion;
  final String code;
  final DateTime createdAt;
  final SubmissionSyncState syncState;
  final int attemptCount;
  final DateTime? lastAttemptAt;

  /// Server-side identifier for the graded submission, once known.
  final String? serverResponseRef;

  /// Server verdict, e.g. "accepted", "needs_work", "graded".
  final String? serverStatus;

  final String? lastError;

  Submission copyWith({
    SubmissionSyncState? syncState,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? serverResponseRef,
    String? serverStatus,
    String? lastError,
  }) =>
      Submission(
        id: id,
        learnerRef: learnerRef,
        exerciseId: exerciseId,
        exerciseVersion: exerciseVersion,
        code: code,
        createdAt: createdAt,
        syncState: syncState ?? this.syncState,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        serverResponseRef: serverResponseRef ?? this.serverResponseRef,
        serverStatus: serverStatus ?? this.serverStatus,
        lastError: lastError ?? this.lastError,
      );

  /// Payload sent to the LMS. Note the deliberate absence of personal data.
  Map<String, dynamic> toApiJson() => {
        'submissionId': id,
        'exerciseId': exerciseId,
        'exerciseVersion': exerciseVersion,
        'code': code,
        'clientCreatedAt': createdAt.toUtc().toIso8601String(),
      };

  Map<String, Object?> toDbMap() => {
        'submission_id': id,
        'learner_ref': learnerRef,
        'exercise_id': exerciseId,
        'exercise_version': exerciseVersion,
        'code': code,
        'created_at': createdAt.millisecondsSinceEpoch,
        'sync_state': syncState.name,
        'attempt_count': attemptCount,
        'last_attempt_at': lastAttemptAt?.millisecondsSinceEpoch,
        'server_response_ref': serverResponseRef,
        'server_status': serverStatus,
        'last_error': lastError,
      };

  factory Submission.fromDbMap(Map<String, Object?> map) => Submission(
        id: map['submission_id'] as String,
        learnerRef: map['learner_ref'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseVersion: (map['exercise_version'] as num).toInt(),
        code: map['code'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch((map['created_at'] as num).toInt()),
        syncState: SubmissionSyncState.fromName(map['sync_state'] as String),
        attemptCount: (map['attempt_count'] as num?)?.toInt() ?? 0,
        lastAttemptAt: map['last_attempt_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((map['last_attempt_at'] as num).toInt()),
        serverResponseRef: map['server_response_ref'] as String?,
        serverStatus: map['server_status'] as String?,
        lastError: map['last_error'] as String?,
      );
}
