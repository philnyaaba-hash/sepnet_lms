/// A short teaching sequence shown *before* the learner attempts an exercise.
///
/// The shape is deliberately tiny: a lesson is a list of [LessonStep]s, and
/// each step is one idea expressed as prose, optionally with a code example.
/// That is enough to reproduce the "one thought per screen" rhythm that makes
/// the reference app's lessons readable to a 12-year-old, without inventing a
/// slide format we would have to author tooling for.
///
/// Offline: lessons ride along inside the cached [Exercise] payload, so they
/// cost nothing extra to keep available with no connection.
class Lesson {
  const Lesson({required this.steps});

  /// Ordered teaching steps. Never empty for a lesson we choose to display.
  final List<LessonStep> steps;

  /// How many screens the learner taps through.
  int get stepCount => steps.length;

  factory Lesson.fromJson(Object? json) {
    if (json is! Map) return const Lesson(steps: []);
    final raw = json['steps'];
    if (raw is! List) return const Lesson(steps: []);
    return Lesson(
      steps: raw
          .map(LessonStep.fromJson)
          .where((step) => step.isNotEmpty)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
        'steps': steps.map((s) => s.toJson()).toList(growable: false),
      };

  /// True when there is nothing worth showing, so callers can skip straight to
  /// the exercise rather than presenting an empty screen.
  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isEmpty == false;
}

/// One screen of teaching.
class LessonStep {
  const LessonStep({required this.prose, this.exampleCode});

  /// The teaching text. May contain `backticks`, which render as boxed code
  /// chips rather than literal characters — see [InlineCodeText].
  final String prose;

  /// Optional runnable-looking example shown under the prose.
  final String? exampleCode;

  bool get isEmpty =>
      prose.trim().isEmpty && (exampleCode?.trim().isEmpty ?? true);

  bool get isNotEmpty => !isEmpty;

  factory LessonStep.fromJson(Object? json) {
    if (json is! Map) return const LessonStep(prose: '');
    return LessonStep(
      prose: (json['prose'] as String?) ?? '',
      exampleCode: json['exampleCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'prose': prose,
        if (exampleCode != null) 'exampleCode': exampleCode,
      };
}
