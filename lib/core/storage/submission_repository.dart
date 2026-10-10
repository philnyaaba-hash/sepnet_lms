import 'package:sqflite/sqflite.dart';

import 'package:skillbridge_python_lab/core/storage/app_database.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';

/// Durable queue + history for submissions. The queue survives app restarts
/// and is only cleared when a submission reaches a terminal state *and* the
/// app chooses to prune accepted history.
class SubmissionRepository {
  SubmissionRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  /// Inserts a new submission. Returns `false` when a submission with the same
  /// id already exists, which is the local half of duplicate protection.
  Future<bool> enqueue(Submission submission) async {
    final existing = await findById(submission.id);
    if (existing != null) return false;
    await _db.insert(
      'submissions',
      submission.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return true;
  }

  Future<Submission?> findById(String id) async {
    final rows = await _db.query(
      'submissions',
      where: 'submission_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Submission.fromDbMap(rows.first);
  }

  Future<List<Submission>> listForLearner(
    String learnerRef, {
    SubmissionSyncState? state,
    int limit = 100,
  }) async {
    final rows = await _db.query(
      'submissions',
      where: state == null ? 'learner_ref = ?' : 'learner_ref = ? AND sync_state = ?',
      whereArgs: state == null ? [learnerRef] : [learnerRef, state.name],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(Submission.fromDbMap).toList();
  }

  /// Submissions that still need to reach the server, oldest first (FIFO).
  Future<List<Submission>> pending(String learnerRef) async {
    final rows = await _db.query(
      'submissions',
      where: "learner_ref = ? AND sync_state IN ('pending','failed')",
      whereArgs: [learnerRef],
      orderBy: 'created_at ASC',
    );
    return rows.map(Submission.fromDbMap).toList();
  }

  Future<int> pendingCount(String learnerRef) async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) AS c FROM submissions WHERE learner_ref = ? AND sync_state IN ('pending','failed')",
      [learnerRef],
    );
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<void> update(Submission submission) async {
    await _db.update(
      'submissions',
      submission.toDbMap(),
      where: 'submission_id = ?',
      whereArgs: [submission.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.delete('submissions', where: 'submission_id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllFor(String learnerRef) async {
    await _db.delete('submissions', where: 'learner_ref = ?', whereArgs: [learnerRef]);
  }
}
