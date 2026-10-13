import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/widgets/chunky_button.dart';

/// Celebration screen: trophy pops in, stars appear, XP counts up.
/// The XP shown is what the lesson OFFERS. It is not confirmed until the
/// SkillBridge server verifies the result.
class CompletionView extends StatelessWidget {
  const CompletionView({
    super.key,
    required this.xpOffered,
    required this.onFinish,
  });

  final int xpOffered;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 600 + i * 250),
                      curve: Curves.elasticOut,
                      builder: (context, s, child) =>
                          Transform.scale(scale: s, child: child),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star_rounded,
                          size: i == 1 ? 56 : 40,
                          color: SkillBridgeColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, s, child) =>
                    Transform.scale(scale: s, child: child),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    color: SkillBridgeColors.surfaceHigh,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 80,
                    color: SkillBridgeColors.accent,
                    semanticLabel: 'Trophy',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Lesson complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: xpOffered),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                builder: (context, v, _) => Text(
                  '+$v XP',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: SkillBridgeColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Your XP is confirmed by SkillBridge when you are online.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: SkillBridgeColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        ChunkyButton(label: 'FINISH', onPressed: onFinish),
      ],
    );
  }
}
