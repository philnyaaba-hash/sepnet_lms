import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/widgets/animated_bits.dart';
import '../../shared/widgets/chunky_button.dart';
import 'lesson_models.dart';

// ---------------------------------------------------------------------------
// Read step: paragraphs fade/slide in one at a time.
// ---------------------------------------------------------------------------
class ReadStepView extends StatefulWidget {
  const ReadStepView({super.key, required this.step, required this.onNext});
  final ReadStep step;
  final VoidCallback onNext;

  @override
  State<ReadStepView> createState() => _ReadStepViewState();
}

class _ReadStepViewState extends State<ReadStepView> {
  int _shown = 1;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_shown < widget.step.paragraphs.length) {
      setState(() => _shown++);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _shown; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: FadeSlideIn(
                      key: ValueKey('p$i'),
                      child: Text(
                        widget.step.paragraphs[i],
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.6,
                          color: SkillBridgeColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ChunkyButton(label: 'CONTINUE', onPressed: _onContinue),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Code walk step: highlight each line in turn, show a note and any output.
// ---------------------------------------------------------------------------
class CodeWalkStepView extends StatefulWidget {
  const CodeWalkStepView({super.key, required this.step, required this.onNext});
  final CodeWalkStep step;
  final VoidCallback onNext;

  @override
  State<CodeWalkStepView> createState() => _CodeWalkStepViewState();
}

class _CodeWalkStepViewState extends State<CodeWalkStepView> {
  static const _highlight = Color(0x2E14B8A6);
  int _line = -1;

  bool get _finished => _line >= widget.step.lines.length - 1;

  void _onPressed() {
    if (_finished) {
      widget.onNext();
    } else {
      setState(() => _line++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.step.lines;
    final outputs = <String>[
      for (var i = 0; i <= _line; i++)
        if (lines[i].output != null) lines[i].output!,
    ];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: SkillBridgeColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: SkillBridgeColors.surfaceHigh,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: i == _line ? _highlight : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                width: 4,
                                color: i == _line
                                    ? SkillBridgeColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    color: SkillBridgeColors.primary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  lines[i].code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16,
                                    color: SkillBridgeColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _line >= 0
                        ? lines[_line].note
                        : 'Tap START to watch Python read the code.',
                    key: ValueKey(_line),
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: SkillBridgeColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 72),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OUTPUT',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: SkillBridgeColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (var j = 0; j < outputs.length; j++)
                        FadeSlideIn(
                          key: ValueKey('out$j'),
                          child: Text(
                            outputs[j],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              color: SkillBridgeColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ChunkyButton(
          label: _finished ? 'CONTINUE' : (_line < 0 ? 'START' : 'NEXT LINE'),
          onPressed: _onPressed,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quiz step: select, check, shake on wrong, bounce on correct, feedback banner.
// ---------------------------------------------------------------------------
class QuizStepView extends StatefulWidget {
  const QuizStepView({super.key, required this.step, required this.onNext});
  final QuizStep step;
  final VoidCallback onNext;

  @override
  State<QuizStepView> createState() => _QuizStepViewState();
}

class _QuizStepViewState extends State<QuizStepView> {
  int? _selected;
  bool _checked = false;
  bool _isCorrect = false;
  int _shake = 0;

  void _check() {
    final ok = _selected == widget.step.correctIndex;
    setState(() {
      _checked = true;
      _isCorrect = ok;
      if (!ok) _shake++;
    });
    HapticFeedback.lightImpact();
  }

  void _retry() => setState(() {
        _checked = false;
        _selected = null;
      });

  Widget _option(int i) {
    final selected = _selected == i;
    var border = selected ? SkillBridgeColors.primary : SkillBridgeColors.surfaceHigh;
    if (_checked && selected) {
      border = _isCorrect ? SkillBridgeColors.success : SkillBridgeColors.error;
    }

    Widget tile = Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _checked ? null : () => setState(() => _selected = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: SkillBridgeColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 2),
            boxShadow: [BoxShadow(color: border, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.step.options[i],
                  style: const TextStyle(
                    fontSize: 17,
                    color: SkillBridgeColors.textPrimary,
                  ),
                ),
              ),
              if (_checked && selected)
                Icon(
                  _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: border,
                ),
            ],
          ),
        ),
      ),
    );

    if (_checked && selected && !_isCorrect) {
      tile = TweenAnimationBuilder<double>(
        key: ValueKey('shake$_shake'),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        builder: (context, t, child) => Transform.translate(
          offset: Offset(math.sin(t * math.pi * 6) * 10 * (1 - t), 0),
          child: child,
        ),
        child: tile,
      );
    } else if (_checked && selected && _isCorrect) {
      tile = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: tile,
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: tile);
  }

  Widget _banner() {
    final color = _isCorrect ? SkillBridgeColors.success : SkillBridgeColors.error;
    return Container(
      key: ValueKey('banner$_isCorrect'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SkillBridgeColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCorrect ? 'Nice work!' : 'Not quite',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.step.explanation,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
              color: SkillBridgeColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String label;
    final VoidCallback? action;
    if (!_checked) {
      label = 'CHECK';
      action = _selected == null ? null : _check;
    } else if (_isCorrect) {
      label = 'CONTINUE';
      action = widget.onNext;
    } else {
      label = 'TRY AGAIN';
      action = _retry;
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.question,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                for (var i = 0; i < widget.step.options.length; i++) _option(i),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _checked ? _banner() : const SizedBox.shrink(key: ValueKey('none')),
        ),
        ChunkyButton(label: label, onPressed: action),
      ],
    );
  }
}
