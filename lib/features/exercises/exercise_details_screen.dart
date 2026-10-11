import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:skillbridge_python_lab/core/di/app_dependencies.dart';
import 'package:skillbridge_python_lab/features/exercises/exercise.dart';
import 'package:skillbridge_python_lab/features/submissions/submission.dart';

/// Screen D: Exercise details — objectives, requirements, starter code, hints
/// and the learner's current submission status.
class ExerciseDetailsScreen extends StatefulWidget {
  const ExerciseDetailsScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseDetailsScreen> createState() => _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends State<ExerciseDetailsScreen> {
  int _revealedHints = 0;
  Submission? _latest;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final deps = context.read<AppDependencies>();
    try {
      final submissions = await deps.submissions.listForLearner(deps.learnerRef);
      final mine =
          submissions.where((s) => s.exerciseId == widget.exercise.id).toList();
      if (mounted) {
        setState(() {
          _latest = mine.isEmpty ? null : mine.first;
          _loading = false;
        });
      }
    } catch (_) {
      // History is optional; never let a storage hiccup escape initState.
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(exercise.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusChip(latest: _latest, loading: _loading),
          const SizedBox(height: 16),
          _Heading('Instructions'),
          Text(exercise.instructions, style: theme.textTheme.bodyLarge),
          if (exercise.objectives.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Heading('What you will learn'),
            for (final objective in exercise.objectives)
              _Bullet(icon: Icons.school_outlined, text: objective),
          ],
          if (exercise.requirements.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Heading('Requirements'),
            for (final requirement in exercise.requirements)
              _Bullet(icon: Icons.check_circle_outline, text: requirement),
          ],
          const SizedBox(height: 20),
          _Heading('Starter code'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1B2D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              exercise.starterCode.isEmpty ? '(empty)' : exercise.starterCode,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFE6EAF0)),
            ),
          ),
          if (exercise.hints.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Heading('Hints'),
            for (var i = 0; i < _revealedHints && i < exercise.hints.length; i++)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb_outline, color: Colors.orange),
                  title: Text(exercise.hints[i]),
                ),
              ),
            if (_revealedHints < exercise.hints.length)
              OutlinedButton.icon(
                onPressed: () => setState(() => _revealedHints++),
                icon: const Icon(Icons.visibility_outlined),
                label: Text('Show hint ${_revealedHints + 1} of ${exercise.hints.length}'),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _start(),
            icon: Icon(exercise.hasLesson ? Icons.menu_book_outlined : Icons.code),
            label: Text(exercise.hasLesson ? 'Start with a quick lesson' : 'Start coding'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Entry point for the primary button.
  ///
  /// With a lesson: teaching first, then straight into the editor on CONTINUE,
  /// so the learner never has to navigate back through the details screen to
  /// reach the task. Without one: straight to the editor, as before.
  Future<void> _start() async {
    final exercise = widget.exercise;
    if (!exercise.hasLesson) {
      await Navigator.of(context).pushNamed('/editor', arguments: exercise);
    } else {
      await Navigator.of(context).pushNamed(
        '/lesson',
        arguments: {
          'exercise': exercise,
          'onFinished': () {
            // Replace rather than push so Back from the editor does not
            // re-enter the lesson the learner has already completed.
            Navigator.of(context).pushReplacementNamed('/editor',
                arguments: exercise);
          },
        },
      );
    }
    if (mounted) await _loadStatus();
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.latest, required this.loading});

  final Submission? latest;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator();
    final submission = latest;
    late String label;
    late Color color;
    late IconData icon;
    if (submission == null) {
      label = 'Not submitted yet';
      color = Colors.grey;
      icon = Icons.radio_button_unchecked;
    } else {
      switch (submission.syncState) {
        case SubmissionSyncState.pending:
          label = 'Saved — waiting to send';
          color = Colors.orange;
          icon = Icons.schedule;
        case SubmissionSyncState.syncing:
          label = 'Sending…';
          color = Colors.blue;
          icon = Icons.cloud_upload;
        case SubmissionSyncState.accepted:
          label = 'Accepted by the LMS';
          color = const Color(0xFF2E7D32);
          icon = Icons.verified;
        case SubmissionSyncState.rejected:
          label = 'Not accepted yet — try again';
          color = const Color(0xFFB71C1C);
          icon = Icons.refresh;
        case SubmissionSyncState.failed:
          label = 'Saved — will retry';
          color = Colors.orange;
          icon = Icons.cloud_off;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
