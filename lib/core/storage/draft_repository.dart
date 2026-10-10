import 'package:sqflite/sqflite.dart';

import 'package:skillbridge_python_lab/core/storage/app_database.dart';

/// A locally saved snapshot of a learner's code for an exercise.
class Draft {
  const Draft({
    required this.learnerRef,
    required this.exerciseId,
    required this.exerciseVersion,
    required this.code,
    required this.updatedAt,
  });

  final String learnerRef;
  final String exerciseId;
  final int exerciseVersion;
  final String code;
  final DateTime updatedAt;

  factory Draft.fromDbMap(Map<String, Object?> map) => Draft(
        learnerRef: map['learner_ref'] as String,
        exerciseId: map['exercise_id'] as String,
        exerciseVersion: (map['exercise_version'] as num).toInt(),
        code: map['code'] as String,
        updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updated_at'] as num).toInt()),
      );
}

/// Stores the current working copy of each exercise's code, per learner.
/// This is what makes "edit and run offline, come back later" work.
class DraftRepository {
  DraftRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  Future<void> save({
    required String learnerRef,
    required String exerciseId,
    required int exerciseVersion,
    required String code,
    DateTime? updatedAt,
  }) async {
    await _db.insert(
      'drafts',
      {
        'learner_ref': learnerRef,
        'exercise_id': exerciseId,
        'exercise_version': exerciseVersion,
        'code': code,
        'updated_at': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Draft?> find(String learnerRef, String exerciseId) async {
    final rows = await _db.query(
      'drafts',
      where: 'learner_ref = ? AND exercise_id = ?',
      whereArgs: [learnerRef, exerciseId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Draft.fromDbMap(rows.first);
  }

  Future<List<Draft>> listFor(String learnerRef, {int limit = 20}) async {
    final rows = await _db.query(
      'drafts',
      where: 'learner_ref = ?',
      whereArgs: [learnerRef],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map(Draft.fromDbMap).toList();
  }

  Future<void> delete(String learnerRef, String exerciseId) async {
    await _db.delete(
      'drafts',
      where: 'learner_ref = ? AND exercise_id = ?',
      whereArgs: [learnerRef, exerciseId],
    );
  }

  /// Privacy control: remove every local draft for a learner.
  Future<void> deleteAllFor(String learnerRef) async {
    await _db.delete('drafts', where: 'learner_ref = ?', whereArgs: [learnerRef]);
  }
}
