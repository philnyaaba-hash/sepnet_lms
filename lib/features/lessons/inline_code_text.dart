import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/app/theme.dart';

/// One piece of parsed lesson prose: either plain text or a code token.
class CodeSegment {
  const CodeSegment(this.text, this.isCode);

  final String text;
  final bool isCode;
}

/// Renders teaching prose in which `backticked` spans appear as **boxed code
/// chips** instead of literal characters.
///
/// Why this exists
/// ---------------
/// A beginner cannot yet tell code apart from English. Putting `if` in a
/// bordered monospace box inside the sentence does that separation visually,
/// so the sentence can stay short and spoken rather than formal. It is the
/// single most reusable idea in the reference material
/// (`docs/PRODUCT_REFERENCE.md`).
///
/// Parsing is deliberately naive: split on the backtick. Odd-indexed segments
/// are code. An unmatched trailing backtick renders as literal text rather
/// than throwing, because this content is authored by hand and will one day
/// arrive from an LMS we do not control.
///
/// Layout uses [WidgetSpan] rather than a [Wrap], so chips participate in
/// normal text flow and wrap at line boundaries like any other word.
class InlineCodeText extends StatelessWidget {
  const InlineCodeText(
    this.text, {
    super.key,
    this.style,
    this.animate = true,
    this.onTapCode,
  });

  final String text;

  /// Base prose style. Falls back to the theme's `bodyLarge`, which already
  /// responds to the system text-scale factor.
  final TextStyle? style;

  /// Whether chips animate in on first build. Tests turn this off so the
  /// expected text is present immediately.
  final bool animate;

  /// Optional handler, so a future lesson can make a chip tappable (for
  /// example to insert it into the editor). Not wired up yet.
  final void Function(String code)? onTapCode;

  /// Splits on backticks: even indices are prose, odd indices are code.
  ///
  /// The final odd index only counts as code when a closing backtick follows
  /// it. With an unmatched trailing backtick the remainder has nothing to close
  /// against, so it stays prose rather than opening a span that never ends —
  /// which is exactly the shape a hand-authored (or LMS-authored) sentence like
  /// "use the ` character" takes.
  static List<CodeSegment> parse(String source) {
    final parts = source.split('`');
    final segments = <CodeSegment>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isCode = i.isOdd && i < parts.length - 1;
      segments.add(CodeSegment(parts[i], isCode));
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = style ?? theme.textTheme.bodyLarge;
    final segments = parse(text);

    if (segments.isEmpty) {
      // A string that is entirely backticks, or empty: show nothing rather
      // than an awkward blank line.
      return const SizedBox.shrink();
    }

    var chipIndex = 0;
    final children = <InlineSpan>[];
    for (final segment in segments) {
      if (segment.isCode) {
        final code = segment.text;
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _CodeChip(
              code: code,
              index: chipIndex++,
              animate: animate,
              onTap: onTapCode == null ? null : () => onTapCode!(code),
            ),
          ),
        );
      } else {
        children.add(TextSpan(text: segment.text));
      }
    }

    return Text.rich(TextSpan(style: base, children: children));
  }
}

/// A single boxed code token.
///
/// The palette is **inverted** relative to the surface — light chip on the
/// dark theme, dark chip on the light theme — which is what makes the code
/// read as a distinct object rather than emphasised prose.
class _CodeChip extends StatefulWidget {
  const _CodeChip({
    required this.code,
    required this.index,
    required this.animate,
    this.onTap,
  });

  final String code;
  final int index;
  final bool animate;
  final VoidCallback? onTap;

  @override
  State<_CodeChip> createState() => _CodeChipState();
}

class _CodeChipState extends State<_CodeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  /// Total run time for the staggered entrance of every chip on screen.
  static const Duration _total = Duration(milliseconds: 420);
  static const Duration _stagger = Duration(milliseconds: 70);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _total);
    // Later chips start later, but never long enough to feel like waiting.
    final delayMs =
        (_stagger.inMilliseconds * widget.index).clamp(0, _total.inMilliseconds - 120);
    final start = delayMs / _total.inMilliseconds;
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, 1, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, 1, curve: Curves.easeOutCubic),
      ),
    );
    if (widget.animate) {
      _controller.forward();
    } else {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Inverted against the surface. Both are theme-derived so a future theme
    // change keeps the contrast relationship.
    final chipBackground =
        isDark ? const Color(0xFFE8EDF4) : AppTheme.codeSurface;
    final chipForeground =
        isDark ? const Color(0xFF111A26) : const Color(0xFFF2F5F9);
    final chipBorder =
        isDark ? const Color(0xFFB9C4D2) : const Color(0xFF243447);

    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipBorder, width: 1),
      ),
      child: Text(
        widget.code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13.5,
          height: 1.5,
          fontWeight: FontWeight.w600,
          color: chipForeground,
        ),
      ),
    );

    // Semantics: expose the chip as a single readable element so a screen
    // reader says "if" rather than spelling the box decoration. `container` is
    // what stops it being absorbed into the surrounding paragraph's node —
    // without it the label disappears into the prose and is never announced.
    final semantics = Semantics(
      container: true,
      label: widget.code,
      button: widget.onTap != null,
      excludeSemantics: true,
      child: content,
    );

    final wrapped = widget.onTap == null
        ? semantics
        : InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(6),
            child: semantics,
          );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: wrapped),
    );
  }
}

/// A standalone code block for lesson examples: same inverted chip language,
/// but as a full-width block.
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key, this.animate = true});

  final String code;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppTheme.codeSurface : const Color(0xFFEDF1F6);
    final foreground = isDark ? const Color(0xFFE6EAF0) : const Color(0xFF14202E);
    final border =
        isDark ? const Color(0xFF243447) : const Color(0xFFCBD4E0);

    final block = Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: foreground,
        ),
      ),
    );

    if (!animate) return block;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child:
            Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: block,
    );
  }
}
