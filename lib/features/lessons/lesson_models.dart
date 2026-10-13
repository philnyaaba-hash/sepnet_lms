/// Lesson content model. Later these will be parsed from LMS JSON and cached
/// in SQLite for offline use. The sample lesson in sample_lesson.dart is
/// original SkillBridge text.
sealed class LessonStep {
  const LessonStep();
}

/// Short text cards revealed one paragraph at a time.
class ReadStep extends LessonStep {
  const ReadStep({required this.paragraphs});
  final List<String> paragraphs;
}

/// One line of a scripted code walk-through.
class CodeLine {
  const CodeLine({required this.code, required this.note, this.output});
  final String code;
  final String note;
  final String? output;
}

/// Scripted, animated "watch Python read the code line by line" step.
/// NOTE: this is a teaching animation with authored output. It does not
/// execute code. Real execution lives in the Python editor/runtime.
class CodeWalkStep extends LessonStep {
  const CodeWalkStep({required this.title, required this.lines});
  final String title;
  final List<CodeLine> lines;
}

/// Multiple-choice question. The correct index here is for instant feedback in
/// the lesson only; rewards and completion are decided by the LMS server.
class QuizStep extends LessonStep {
  const QuizStep({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.xpOffered,
    required this.steps,
  });
  final String id;
  final String title;

  /// Display only. The LMS decides what is actually granted.
  final int xpOffered;
  final List<LessonStep> steps;
}
