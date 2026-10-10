import 'package:sqflite/sqflite.dart';

import 'package:skillbridge_python_lab/core/storage/app_database.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';

/// Caches exercise metadata so previously seen exercises remain usable offline.
class ExerciseRepository {
  ExerciseRepository(this._database);

  final AppDatabase _database;

  Database get _db => _database.db;

  Future<void> upsertAll(List<Exercise> exercises) async {
    final batch = _db.batch();
    for (final exercise in exercises) {
      batch.insert(
        'exercises',
        {
          'exercise_id': exercise.id,
          'lesson_id': exercise.lessonId,
          'title': exercise.title,
          'instructions': exercise.instructions,
          'objectives': _join(exercise.objectives),
          'starter_code': exercise.starterCode,
          'requirements': _join(exercise.requirements),
          'hints': _join(exercise.hints),
          'version': exercise.version,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Exercise>> listAll({int limit = 100}) async {
    final rows = await _db.query('exercises', orderBy: 'updated_at DESC', limit: limit);
    return rows.map(_fromRow).toList();
  }

  Future<Exercise?> findById(String id) async {
    final rows = await _db.query(
      'exercises',
      where: 'exercise_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS c FROM exercises');
    return (result.first['c'] as num?)?.toInt() ?? 0;
  }

  Future<void> clear() async {
    await _db.delete('exercises');
  }

  static String _join(List<String> values) => values.join('\u0001');

  static List<String> _split(Object? value) {
    final text = value as String?;
    if (text == null || text.isEmpty) return const [];
    return text.split('\u0001');
  }

  static Exercise _fromRow(Map<String, Object?> row) => Exercise(
        id: row['exercise_id'] as String,
        lessonId: row['lesson_id'] as String?,
        title: row['title'] as String,
        instructions: row['instructions'] as String,
        starterCode: row['starter_code'] as String,
        objectives: _split(row['objectives']),
        requirements: _split(row['requirements']),
        hints: _split(row['hints']),
        version: (row['version'] as num).toInt(),
      );
}
