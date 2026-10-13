import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// How the buddy feels. Drives the eyes, mouth, arms and sparkles.
enum BuddyMood { happy, thinking, celebrate, oops }

/// "Bit": SkillBridge's original coding buddy, drawn entirely in code (no
/// image assets, so it works offline and costs almost no storage).
///
/// Animated: gentle bobbing, blinking, a glowing antenna and a waving arm.
/// Respects the system "remove animations" setting (stays still).
class CodeBuddy extends StatefulWidget {
  const CodeBuddy({
    super.key,
    this.size = 110,
    this.mood = BuddyMood.happy,
    this.semanticLabel = 'Bit, your coding buddy',
  });

  final double size;
  final BuddyMood mood;
  final String semanticLabel;

  @override
  State<CodeBuddy> createState() => _CodeBuddyState();
}

class _CodeBuddyState extends State<CodeBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _BuddyPainter(t: _controller.value, mood: widget.mood),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The buddy with a speech bubble. The message cross-fades when it changes.
class BuddySays extends StatelessWidget {
  const BuddySays({
    super.key,
    required this.message,
    this.mood = BuddyMood.happy,
    this.size = 78,
  });

  final String message;
  final BuddyMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CodeBuddy(size: size, mood: mood),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SkillBridgeColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: SkillBridgeColors.outline, width: 1.4),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                message,
                key: ValueKey(message),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: SkillBridgeColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({required this.t, required this.mood});

  /// 0..1 progress through one 3.6 second loop.
  final double t;
  final BuddyMood mood;

  static const _mint = Color(0xFF7DF9E1);
  static const _blueDark = Color(0xFF0F6FE0);
  static const _screen = Color(0xFF0B2547);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * 2 * math.pi;
    final bob = math.sin(phase) * 4;
    final wave = math.sin(phase * 2);

    canvas.save();
    canvas.scale(size.width / 200);

    // Ground shadow (does not bob).
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 190),
        width: 90 - bob * 2,
        height: 12,
      ),
      Paint()..color = const Color(0x33000000),
    );

    canvas.translate(0, bob);

    final armPaint = Paint()
      ..color = _blueDark
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final handPaint = Paint()..color = const Color(0xFF2BA8FF);

    // Arms: the pose depends on the mood.
    late final Offset leftHand;
    late final Offset rightHand;
    switch (mood) {
      case BuddyMood.celebrate:
        leftHand = Offset(14, 84 + wave * 8);
        rightHand = Offset(186, 84 - wave * 8);
      case BuddyMood.thinking:
        leftHand = const Offset(22, 152);
        rightHand = const Offset(146, 108);
      case BuddyMood.oops:
        leftHand = const Offset(26, 118);
        rightHand = const Offset(174, 118);
      case BuddyMood.happy:
        leftHand = Offset(18, 154 + wave * 3);
        rightHand = Offset(184, 146 - wave * 12);
    }
    canvas.drawLine(const Offset(38, 130), leftHand, armPaint);
    canvas.drawLine(const Offset(162, 130), rightHand, armPaint);
    canvas.drawCircle(leftHand, 8, handPaint);
    canvas.drawCircle(rightHand, 8, handPaint);

    // Feet.
    final footPaint = Paint()..color = _blueDark;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(62, 160, 28, 14),
        const Radius.circular(7),
      ),
      footPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(110, 160, 28, 14),
        const Radius.circular(7),
      ),
      footPaint,
    );

    // Antenna with a pulsing gold bulb.
    canvas.drawLine(
      const Offset(100, 38),
      const Offset(100, 20),
      Paint()
        ..color = const Color(0xFF7FB8FF)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final glow = 0.5 + 0.5 * math.sin(phase * 2);
    canvas.drawCircle(
      const Offset(100, 14),
      11,
      Paint()..color = SkillBridgeColors.accent.withValues(alpha: 0.12 + glow * 0.30),
    );
    canvas.drawCircle(const Offset(100, 14), 6.5, Paint()..color = SkillBridgeColors.accent);

    // Ears.
    for (final x in const [32.0, 168.0]) {
      canvas.drawCircle(Offset(x, 100), 11, Paint()..color = _blueDark);
      canvas.drawCircle(Offset(x, 100), 5, Paint()..color = _screen);
    }

    // Body.
    const bodyRect = Rect.fromLTWH(34, 36, 132, 128);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(46)),
      Paint()..shader = SkillBridgeColors.brandGradient.createShader(bodyRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(48, 42, 58, 9),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0x44FFFFFF),
    );

    // Face screen.
    final screen = RRect.fromRectAndRadius(
      const Rect.fromLTWH(48, 58, 104, 66),
      const Radius.circular(30),
    );
    canvas.drawRRect(screen, Paint()..color = _screen);
    canvas.drawRRect(
      screen,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x332BA8FF),
    );

    // Eyes.
    final mintFill = Paint()..color = _mint;
    final mintStroke = Paint()
      ..color = _mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final blinking = t > 0.93 && t < 0.97;
    final look = mood == BuddyMood.thinking ? const Offset(4, -4) : Offset.zero;

    void drawEye(Offset c) {
      if (mood == BuddyMood.celebrate) {
        final path = Path()
          ..moveTo(c.dx - 9, c.dy + 5)
          ..quadraticBezierTo(c.dx, c.dy - 9, c.dx + 9, c.dy + 5);
        canvas.drawPath(path, mintStroke);
      } else if (blinking) {
        canvas.drawLine(Offset(c.dx - 8, c.dy), Offset(c.dx + 8, c.dy), mintStroke);
      } else {
        final center = c + look;
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: 16,
            height: mood == BuddyMood.oops ? 15 : 22,
          ),
          mintFill,
        );
        canvas.drawCircle(
          center + const Offset(-3, -5),
          3,
          Paint()..color = Colors.white,
        );
      }
    }

    drawEye(const Offset(80, 88));
    drawEye(const Offset(120, 88));

    // Mouth.
    switch (mood) {
      case BuddyMood.happy:
        canvas.drawPath(
          Path()
            ..moveTo(86, 106)
            ..quadraticBezierTo(100, 121, 114, 106),
          mintStroke,
        );
      case BuddyMood.celebrate:
        canvas.drawPath(
          Path()
            ..moveTo(84, 103)
            ..quadraticBezierTo(100, 130, 116, 103)
            ..close(),
          mintFill,
        );
      case BuddyMood.thinking:
        canvas.drawLine(const Offset(90, 111), const Offset(108, 107), mintStroke);
      case BuddyMood.oops:
        canvas.drawPath(
          Path()
            ..moveTo(88, 115)
            ..quadraticBezierTo(100, 102, 112, 115),
          mintStroke,
        );
        // Sweat drop.
        canvas.drawPath(
          Path()
            ..moveTo(158, 50)
            ..quadraticBezierTo(150, 64, 158, 70)
            ..quadraticBezierTo(166, 64, 158, 50),
          Paint()..color = const Color(0xFF9AD7FF),
        );
    }

    // Cheeks.
    final cheek = Paint()..color = const Color(0x66FF8FB1);
    canvas.drawCircle(const Offset(65, 108), 7, cheek);
    canvas.drawCircle(const Offset(135, 108), 7, cheek);

    // Chest badge: </>
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(70, 134, 60, 22),
        const Radius.circular(11),
      ),
      Paint()..color = const Color(0x33FFFFFF),
    );
    final badge = TextPainter(
      text: const TextSpan(
        text: '</>',
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    badge.paint(canvas, Offset(100 - badge.width / 2, 145 - badge.height / 2));

    // Sparkles when celebrating.
    if (mood == BuddyMood.celebrate) {
      const spots = [Offset(24, 46), Offset(178, 38), Offset(190, 112)];
      for (var i = 0; i < spots.length; i++) {
        final r = 7 + 3 * math.sin(phase * 2 + i * 1.7);
        _star(canvas, spots[i], r, Paint()..color = SkillBridgeColors.accent);
      }
    }

    canvas.restore();
  }

  void _star(Canvas canvas, Offset o, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = math.pi / 4 * i - math.pi / 2;
      final rr = i.isEven ? r : r * 0.38;
      final p = Offset(o.dx + math.cos(a) * rr, o.dy + math.sin(a) * rr);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BuddyPainter old) => old.t != t || old.mood != mood;
}
