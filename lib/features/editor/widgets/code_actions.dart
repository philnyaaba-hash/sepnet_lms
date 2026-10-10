import 'package:flutter/widgets.dart';

/// Pure text-manipulation helpers used by the shortcut bar.
///
/// All operations mutate the controller's [TextEditingValue] in one step so the
/// cursor and selection are preserved predictably. Unit-tested in
/// `test/code_actions_test.dart`.
class CodeActions {
  const CodeActions._();

  /// Inserts [text] at the current cursor, replacing any selection.
  ///
  /// [cursorOffsetFromStart] positions the caret inside/after the inserted text
  /// (used for snippets such as `print()` where the caret belongs inside).
  static void insert(
    TextEditingController controller,
    String text, {
    int? cursorOffsetFromStart,
  }) {
    final value = controller.value;
    final selection = _safeSelection(value);
    final newText = value.text.replaceRange(selection.start, selection.end, text);
    final caret = selection.start + (cursorOffsetFromStart ?? text.length);
    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: caret.clamp(0, newText.length)),
      composing: TextRange.empty,
    );
  }

  /// Indents every line touched by the selection (or the current line).
  static void indent(TextEditingController controller, String indentUnit) {
    _transformLines(controller, (line) => line.isEmpty ? line : '$indentUnit$line');
  }

  /// Removes up to one indentation level from the affected lines.
  static void dedent(TextEditingController controller, String indentUnit) {
    _transformLines(controller, (line) {
      if (line.startsWith(indentUnit)) return line.substring(indentUnit.length);
      // Fall back to removing up to indentUnit leading spaces.
      var removed = 0;
      while (removed < indentUnit.length && removed < line.length && line[removed] == ' ') {
        removed++;
      }
      return line.substring(removed);
    });
  }

  /// Toggles a `#` comment prefix on the affected lines.
  static void toggleComment(TextEditingController controller) {
    _transformLines(controller, (line) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('#')) {
        final index = line.indexOf('#');
        return line.replaceRange(index, index + 1, '');
      }
      if (line.trim().isEmpty) return line;
      final leading = line.length - trimmed.length;
      return line.replaceRange(leading, leading, '# ');
    });
  }

  static TextSelection _safeSelection(TextEditingValue value) {
    if (!value.selection.isValid) {
      return TextSelection.collapsed(offset: value.text.length);
    }
    return value.selection;
  }

  static void _transformLines(TextEditingController controller, String Function(String) transform) {
    final value = controller.value;
    final text = value.text;
    final selection = _safeSelection(value);

    final start = text.lastIndexOf('\n', selection.start > 0 ? selection.start - 1 : 0) + 1;
    var end = text.indexOf('\n', selection.end);
    if (end == -1) end = text.length;

    final block = text.substring(start, end);
    final lines = block.split('\n');
    final transformed = lines.map(transform).join('\n');

    final newText = text.replaceRange(start, end, transformed);
    final delta = transformed.length - block.length;
    final newStart = start;
    final newEnd = (selection.end + delta).clamp(newStart, newText.length);

    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection(baseOffset: newStart, extentOffset: newEnd),
      composing: TextRange.empty,
    );
  }
}
