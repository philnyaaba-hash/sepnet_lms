import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Big rounded button with a thick bottom edge that "presses down" when tapped.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = SkillBridgeColors.primary,
    this.textColor = SkillBridgeColors.onPrimary,
  });

  final String label;
  final VoidCallback? onPressed; // null = disabled
  final Color color;
  final Color textColor;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const double _depth = 5;
  static const double _height = 56;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final face = enabled
        ? widget.color
        : Color.lerp(widget.color, SkillBridgeColors.background, 0.65)!;
    final edge = Color.lerp(face, Colors.black, 0.35)!;
    final pressed = _down && enabled;
    final offset = pressed ? _depth : 0.0;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: () => setState(() => _down = false),
          onTap: widget.onPressed,
          child: SizedBox(
            height: _height + _depth,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.only(top: offset),
                height: _height,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: face,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: edge, offset: Offset(0, _depth - offset)),
                  ],
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: enabled
                        ? widget.textColor
                        : SkillBridgeColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
