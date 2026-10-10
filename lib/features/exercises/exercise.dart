/// A Python practice exercise, normally fetched from the LMS and cached locally
/// so it remains available offline.
class Exercise {
  const Exercise({
    required this.id,
    required this.title,
    required this.instructions,
    required this.starterCode,
    this.lessonId,
    this.objectives = const [],
    this.requirements = const [],
    this.hints = const [],
    this.version = 1,
    this.sampleStdin = const [],
    this.expectedOutput,
  });

  final String id;
  final String? lessonId;
  final String title;
  final String instructions;
  final String starterCode;

  /// Learning objectives, shown on the details screen.
  final List<String> objectives;

  /// What the learner must achieve to complete the exercise.
  final List<String> requirements;

  /// Optional progressive hints.
  final List<String> hints;

  /// Monotonic exercise version, used to detect stale submissions.
  final int version;

  /// Sample input lines for exercises that use `input()`.
  final List<String> sampleStdin;

  /// Optional expected output, used for local self-check guidance only. The
  /// authoritative grade always comes from the server.
  final String? expectedOutput;

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        lessonId: json['lessonId'] as String?,
        title: (json['title'] as String?) ?? 'Untitled exercise',
        instructions: (json['instructions'] as String?) ?? '',
        starterCode: (json['starterCode'] as String?) ?? '',
        objectives: _stringList(json['objectives']),
        requirements: _stringList(json['requirements']),
        hints: _stringList(json['hints']),
        version: (json['version'] as num?)?.toInt() ?? 1,
        sampleStdin: _stringList(json['sampleStdin']),
        expectedOutput: json['expectedOutput'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lessonId': lessonId,
        'title': title,
        'instructions': instructions,
        'starterCode': starterCode,
        'objectives': objectives,
        'requirements': requirements,
        'hints': hints,
        'version': version,
        'sampleStdin': sampleStdin,
        'expectedOutput': expectedOutput,
      };

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }
}
