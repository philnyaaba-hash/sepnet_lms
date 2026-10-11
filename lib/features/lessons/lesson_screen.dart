import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/lessons/inline_code_text.dart';
import 'package:skillbridge_python_lab/features/lessons/lesson.dart';

/// Screen: the teaching beat that precedes an exercise.
///
/// Structure follows the reference material closely because it is a good
/// structure, not because it is someone else's: a close affordance, a progress
/// bar, and **one idea per screen** with a single full-width CONTINUE. The
/// learner never faces a wall of text, and there is exactly one thing to tap.
///
/// When the steps run out the screen hands control back to the caller, which
/// is what lets the details screen chain lesson → exercise without this widget
/// needing to know routing exists.
///
/// Accessibility: the progress bar is exposed as a labelled value ("Step 2 of
/// 4"), every step transition is announced, and the CONTINUE button is the
/// only focusable action, so keyboard and switch access stay simple.
class LessonScreen extends StatefulWidget {
  const LessonScreen({
    super.key,
    required this.exercise,
    this.onFinished,
  });

  final Exercise exercise;

  /// Called when the learner taps CONTINUE on the final step. If null, the
  /// screen simply pops.
  final VoidCallback? onFinished;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _index = 0;
  bool _leaving = false;

  /// Direction of the most recent step change: +1 forward, -1 backward. Used
  /// by the transition so steps rise from below when advancing and from above
  /// when going back. A field rather than an InheritedWidget because
  /// `AnimatedSwitcher.transitionBuilder` gets the child widget, not a context
  /// to look one up from.
  double _direction = 1;

  Lesson get _lesson => widget.exercise.lesson;
  bool get _isLast => _index >= _lesson.stepCount - 1;

  void _advance() {
    if (_leaving) return;
    if (_isLast) {
      setState(() => _leaving = true);
      final onFinished = widget.onFinished;
      if (onFinished != null) {
        onFinished();
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }
    setState(() {
      _direction = 1;
      _index++;
    });
  }

  void _back() {
    if (_leaving) return;
    if (_index == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _direction = -1;
      _index--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _lesson.steps;

    // Defensive: an exercise with no lesson should never route here, but a
    // blank screen is a worse failure than leaving immediately.
    if (steps.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final progress = (_index + 1) / steps.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LessonHeader(
              progress: progress,
              stepIndex: _index,
              stepCount: steps.length,
              onBack: _back,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  // Forward: rise from below. Backward: rise from above.
                  final direction = _direction;
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.06 * direction),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: _LessonStepView(step: steps[_index]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Semantics(
                button: true,
                label: _isLast ? 'Start the challenge' : 'Continue',
                child: FilledButton(
                  onPressed: _advance,
                  child: Text(_isLast ? 'Start the challenge' : 'CONTINUE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({
    required this.progress,
    required this.stepIndex,
    required this.stepCount,
    required this.onBack,
  });

  final double progress;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: stepIndex == 0 ? 'Close lesson' : 'Previous step',
            icon: Icon(stepIndex == 0 ? Icons.close : Icons.arrow_back),
          ),
          const SizedBox(width: 4),
          // Semantics lives on the progress indicator itself rather than the
          // bar, so a screen reader announces "Step 2 of 4" not "50%".
          // Expanded must be the direct child of the Row; Semantics wraps the
          // ClipRRect *inside* it, or the ParentData type does not match and
          // the header throws.
          Expanded(
            child: Semantics(
              label: 'Step ${stepIndex + 1} of $stepCount',
              value: '${(progress * 100).round()}%',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Reward preview: what the exercise is worth once accepted.
          // Deliberately quiet — it must not compete with CONTINUE.
          Tooltip(
            message: 'Earn 10 XP when your code is accepted',
            child: Icon(Icons.star_rounded, color: theme.colorScheme.primary, size: 26),
          ),
        ],
      ),
    );
  }
}

class _LessonStepView extends StatelessWidget {
  const _LessonStepView({required this.step});

  final LessonStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prose. The bodyLarge style already scales with the system font
          // size, and the 1.5 line height is what keeps a paragraph readable
          // on a cheap screen at arm's length.
          InlineCodeText(
            step.prose,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              height: 1.55,
            ),
          ),
          if (step.exampleCode != null)
            CodeBlock(step.exampleCode!),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
