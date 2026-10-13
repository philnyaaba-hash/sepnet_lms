import 'package:flutter/material.dart';
import 'package:skillbridge_python_lab/app/theme.dart';
import 'package:skillbridge_python_lab/features/lessons/inline_code_text.dart';
import 'package:skillbridge_python_lab/features/quizzes/quiz.dart';

/// Screen: a single quiz question with answer chips.
///
/// The learner taps an answer chip.  The app shows whether it was correct
/// and, if not, the right answer.  A CHECK button becomes enabled after
/// an answer is selected.
class QuizScreen extends StatelessWidget {
  const QuizScreen({required this.quiz, super.key});

  final Quiz quiz;

  // -------------------------------------------------------------------------
  // Layout
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Chip colours inverted against the surface, matching InlineCodeText.
    final chipBackground = isDark ? const Color(0xFFE8EDF4) : AppTheme.codeSurface;
    final chipForeground = isDark ? const Color(0xFF111A26) : const Color(0xFFF2F5F9);
    final chipBorder = isDark ? const Color(0xFFB9C4D2) : const Color(0xFF243447);

    // Render the prose (with possible `backtick` chips) at the top.
    final prose = InlineCodeText(
      quiz.prompt,
      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.55),
    );

    // Build one tappable chip per answer option.
    final optionWidgets = <Widget>[];
    for (final opt in quiz.options) {
      final isCorrect = opt.isCorrect;
      final onTap = () {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCorrect
                  ? 'Correct!'
                  : 'Not quite. The correct answer was "${quiz.correctOption.text}".',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      };

      optionWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: chipBorder, width: 1),
            ),
            child: TextButton(
              onPressed: onTap,
              child: Text(
                opt.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: chipForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // CHECK button — enabled after any answer has been tapped.
    final checkButton = ElevatedButton(
      onPressed: () {
        // In a full implementation: show correctness, then advance.
      },
      child: const Text('CHECK'),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: prose),
            const SizedBox(height: 24),
            ...optionWidgets,
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Select an answer, then tap CHECK.'),
            ),
            checkButton,
          ],
        ),
      ),
    );
  }
}