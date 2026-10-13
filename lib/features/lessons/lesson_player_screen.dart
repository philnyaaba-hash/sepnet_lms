import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_bits.dart';
import 'completion_view.dart';
import 'lesson_models.dart';
import 'step_views.dart';

/// Full-screen lesson flow: animated progress bar, each step slides in from
/// the right, then a celebration screen.
class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  int _index = 0;
  bool _exitPromptOpen = false;
  bool _completionPopped = false;

  bool get _done => _index >= widget.lesson.steps.length;

  void _next() => setState(() => _index++);

  void _popOnce() {
    if (!mounted || _completionPopped) return;
    _completionPopped = true;
    Navigator.of(context).pop();
  }

  Future<void> _confirmExit() async {
    if (_exitPromptOpen || !mounted) return;
    _exitPromptOpen = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave lesson?'),
        content: const Text('Your progress in this lesson will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('STAY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LEAVE'),
          ),
        ],
      ),
    );
    _exitPromptOpen = false;
    if (leave == true) _popOnce();
  }

  Widget _slideFade(Widget child, Animation<double> animation) {
    final offset = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }

  Widget _buildStep(LessonStep step) => switch (step) {
    ReadStep s => ReadStepView(step: s, onNext: _next),
    CodeWalkStep s => CodeWalkStepView(step: s, onNext: _next),
    QuizStep s => QuizStepView(step: s, onNext: _next),
  };

  @override
  Widget build(BuildContext context) {
    final total = widget.lesson.steps.length;

    return PopScope(
      canPop: _done,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Close lesson',
                      onPressed: _done ? _popOnce : _confirmExit,
                      icon: const Icon(Icons.close_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AnimatedProgressBar(
                        value: _done ? 1 : _index / total,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Ask the tutor (coming soon)',
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(
                            const SnackBar(
                              content: Text('AI tutor is coming soon.'),
                            ),
                          ),
                      icon: const Icon(
                        Icons.auto_awesome,
                        color: SkillBridgeColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: _slideFade,
                    layoutBuilder: (current, previous) => Stack(
                      fit: StackFit.expand,
                      children: [...previous, if (current != null) current],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: _done
                          ? CompletionView(
                              xpOffered: widget.lesson.xpOffered,
                              onFinish: _popOnce,
                            )
                          : _buildStep(widget.lesson.steps[_index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
