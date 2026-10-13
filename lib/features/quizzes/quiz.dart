/// A single quiz question with several tappable answer chips.

class Quiz {
  const Quiz({
    required this.id,
    required this.prompt,
    required this.options,
    this.explanation,
  });

  /// Unique identifier for idempotent caching.
  final String id;
  /// The question text, may contain `backticks` which render as code chips.
  final String prompt;
  /// Distinct answer options.  Exactly one is correct.
  final List<AnswerOption> options;
  /// Human-readable explanation shown after the question is solved.
  final String? explanation;

  /// The index of the correct option in [options].
  int get correctIndex => _correctIndex;
  int _correctIndex = 0;

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
        id: json['id'] as String,
        prompt: json['prompt'] as String,
        options: (json['options'] as List)
            .map((o) => AnswerOption.fromJson(o as Map<String, dynamic>))
            .toList(growable: false),
        explanation: json['explanation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'options': options.map((o) => o.toJson()).toList(),
        if (explanation != null) 'explanation': explanation,
      };

  /// Returns the [AnswerOption] that is correct.
  AnswerOption get correctOption => options[correctIndex];
}

/// One answer choice in a [Quiz].
class AnswerOption {
  const AnswerOption({
    required this.text,
    required this.isCorrect,
  });

  /// The text shown on the chip.  May contain `backticks` which render as
  /// code chips just like [InlineCodeText].
  final String text;
  /// Whether this option is the one correct answer.
  final bool isCorrect;

  factory AnswerOption.fromJson(Map<String, dynamic> json) => AnswerOption(
        text: json['text'] as String,
        isCorrect: json['isCorrect'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'isCorrect': isCorrect,
      };
}