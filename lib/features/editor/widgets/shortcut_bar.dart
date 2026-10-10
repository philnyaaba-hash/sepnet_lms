import 'package:flutter/material.dart';

import 'code_actions.dart';

/// Beginner-friendly shortcut bar.
///
/// Symbol keys are the ones Ghanaian learners most often struggle to reach on a
/// phone keyboard (`:`, brackets, quotes, `=`), plus one-tap Python snippets.
/// Every button inserts at the caret without losing selection or focus.
class ShortcutBar extends StatelessWidget {
  const ShortcutBar({
    super.key,
    required this.controller,
    required this.focusNode,
    this.indentUnit = '    ',
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String indentUnit;

  void _insert(String text, {int? caret}) {
    CodeActions.insert(controller, text, cursorOffsetFromStart: caret);
    focusNode.requestFocus();
  }

  void _indent() {
    CodeActions.indent(controller, indentUnit);
    focusNode.requestFocus();
  }

  void _dedent() {
    CodeActions.dedent(controller, indentUnit);
    focusNode.requestFocus();
  }

  void _comment() {
    CodeActions.toggleComment(controller);
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          children: [
            _key(context, '(', () => _insert('()', caret: 1)),
            _key(context, ')', () => _insert(')')),
            _key(context, '[', () => _insert('[]', caret: 1)),
            _key(context, ']', () => _insert(']')),
            _key(context, '{', () => _insert('{}', caret: 1)),
            _key(context, '}', () => _insert('}')),
            _key(context, "'", () => _insert("''", caret: 1)),
            _key(context, '"', () => _insert('""', caret: 1)),
            _key(context, ':', () => _insert(':')),
            _key(context, '=', () => _insert(' = ')),
            _key(context, '+', () => _insert(' + ')),
            _key(context, '-', () => _insert(' - ')),
            _key(context, '*', () => _insert(' * ')),
            _key(context, '/', () => _insert(' / ')),
            _key(context, '%', () => _insert(' % ')),
            _key(context, '<', () => _insert(' < ')),
            _key(context, '>', () => _insert(' > ')),
            _key(context, ',', () => _insert(', ')),
            const _Divider(),
            _chip(context, 'print', () => _insert('print()', caret: 6)),
            _chip(context, 'input', () => _insert("input('')", caret: 7)),
            _chip(context, 'range', () => _insert('range()', caret: 6)),
            _chip(context, 'if', () => _insert('if :\n', caret: 3)),
            _chip(context, 'else', () => _insert('else:\n')),
            _chip(context, 'for', () => _insert('for i in range():\n', caret: 15)),
            _chip(context, 'while', () => _insert('while :\n', caret: 6)),
            _chip(context, 'def', () => _insert('def name():\n', caret: 4)),
            _chip(context, 'return', () => _insert('return ')),
            _chip(context, 'len', () => _insert('len()', caret: 4)),
            _chip(context, 'True', () => _insert('True')),
            _chip(context, 'False', () => _insert('False')),
            const _Divider(),
            _key(context, '→', _indent, tooltip: 'Indent'),
            _key(context, '←', _dedent, tooltip: 'Unindent'),
            _key(context, '#', _comment, tooltip: 'Comment'),
          ],
        ),
      ),
    );
  }

  Widget _key(BuildContext context, String label, VoidCallback onTap, {String? tooltip}) {
    final child = SizedBox(
      width: 44,
      height: 40,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(44, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: tooltip == null ? child : Tooltip(message: tooltip, child: child),
    );
  }

  Widget _chip(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: VerticalDivider(width: 1),
      );
}
