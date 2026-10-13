import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Thin rounded progress bar that animates smoothly to its new value.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({super.key, required this.value});

  /// 0.0 to 1.0
  final double value;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return Semantics(
      label: 'Lesson progress',
      value: '${(target * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: target),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(height: 14, color: SkillBridgeColors.surfaceHigh),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: Container(
                    height: 14,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SkillBridgeColors.primary,
                          Color(0xFF5EEAD4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Fades a child in while sliding it up slightly.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
