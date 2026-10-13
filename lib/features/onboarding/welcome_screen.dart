import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../lessons/lesson_player_screen.dart';
import '../lessons/sample_lesson.dart';

/// First screen. Placeholder mascot is a simple icon badge; replace with
/// original SkillBridge mascot artwork when it is designed.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _comingSoon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what is not built yet (next milestone).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              const Text(
                'SkillBridge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  color: SkillBridgeColors.primary,
                ),
              ),
              const Text(
                'PYTHON LAB',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 6,
                  color: SkillBridgeColors.textMuted,
                ),
              ),
              const Spacer(),
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: SkillBridgeColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.code_rounded,
                  size: 88,
                  color: SkillBridgeColors.primary,
                  semanticLabel: 'SkillBridge mascot placeholder',
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Learn Python by writing real code, even offline.',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                // Temporary: opens the sample lesson until onboarding exists.
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LessonPlayerScreen(lesson: sampleLesson),
                  ),
                ),
                child: const Text('START LEARNING'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _comingSoon(context, 'LMS login'),
                child: const Text('I ALREADY HAVE AN ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
