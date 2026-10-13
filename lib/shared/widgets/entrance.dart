import 'package:flutter/material.dart';

/// Fades and slides a child up into place. Give each item a rising [index] to
/// get a staggered "cascade" entrance.
///
/// Uses ONE controller with an Interval for the delay, so there are no timers
/// left pending (which would fail widget tests). Respects the system
/// "remove animations" setting by jumping straight to the final state.
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final delayMs = widget.index.clamp(0, 10) * 70;
    final totalMs = 420 + delayMs;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayMs / totalMs, 1.0, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
