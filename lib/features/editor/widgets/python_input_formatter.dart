import 'package:flutter/services.dart';

/// Text input behaviour tailored for Python on a phone:
///  * Auto-closes brackets and quotes.
///  * Skips over a closing quote/bracket the learner just typed.
///  * Wraps an existing selection in brackets/quotes.
///  * Auto-indents the next line, adding an extra level after a `:`.
///
/// Kept as a [TextInputFormatter] so it is fully unit-testable without a real
/// keyboard. See `test/python_input_formatter_test.dart`.
class PythonInputFormatter extends TextInputFormatter {
  PythonInputFormatter({this.indentUnit = '    '});

  final String indentUnit;

  static const Map<String, String> _pairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
  };

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // Locate the changed region (common prefix / suffix).
    var prefix = 0;
    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    var suffixOld = oldText.length;
    var suffixNew = newText.length;
    while (suffixOld > prefix &&
        suffixNew > prefix &&
        oldText[suffixOld - 1] == newText[suffixNew - 1]) {
      suffixOld--;
      suffixNew--;
    }

    final inserted = newText.substring(prefix, suffixNew);
    final hadSelection = !oldValue.selection.isCollapsed;

    // Wrap a selection in brackets/quotes.
    if (hadSelection && inserted.length == 1 && _pairs.containsKey(inserted)) {
      final selected = oldText.substring(
        oldValue.selection.start,
        oldValue.selection.end,
      );
      final closing = _pairs[inserted]!;
      final text = newText.replaceRange(prefix, suffixNew, '$inserted$selected$closing');
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: prefix + 1 + selected.length),
      );
    }

    // Only single-character insertions are special-cased.
    if (inserted.length != 1) {
      return newValue;
    }

    final char = inserted;

    // Auto-close brackets and quotes.
    if (_pairs.containsKey(char)) {
      final closing = _pairs[char]!;

      // A quote is symmetric: when the caret sits immediately in front of an
      // identical quote (typically the one auto-inserted a moment ago), step
      // over it instead of typing a duplicate.
      //
      // The check is based on the *pre-edit* caret position rather than a
      // prefix/suffix diff, because the diff cannot tell `"` inserted before
      // `"` from an untouched run of quotes.
      final caret = oldValue.selection;
      if ((char == '"' || char == "'") &&
          !hadSelection &&
          caret.isCollapsed &&
          caret.baseOffset >= 0 &&
          caret.baseOffset < oldText.length &&
          oldText[caret.baseOffset] == char &&
          _insertAt(oldText, newText, caret.baseOffset, char)) {
        return TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: caret.baseOffset + 1),
        );
      }

      final text = newText.replaceRange(suffixNew, suffixNew, closing);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: prefix + 1),
      );
    }

    // Auto-indent on newline.
    if (char == '\n') {
      // `lastIndexOf` rejects a negative start index, so a newline typed at the
      // very beginning of the buffer (including an empty one) is special-cased.
      final lineStart =
          prefix == 0 ? 0 : newText.lastIndexOf('\n', prefix - 1) + 1;
      final currentLine = newText.substring(lineStart, prefix);
      final leading = _leadingWhitespace(currentLine);
      var indent = leading;
      if (currentLine.trimRight().endsWith(':')) {
        indent = '$leading$indentUnit';
      }
      final text = newText.replaceRange(suffixNew, suffixNew, indent);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: prefix + 1 + indent.length),
      );
    }

    return newValue;
  }

  /// True when [newText] is [oldText] with a single copy of [char] inserted at
  /// [at] — i.e. a plain caret insertion with no deletion or selection.
  static bool _insertAt(String oldText, String newText, int at, String char) =>
      '${oldText.substring(0, at)}$char${oldText.substring(at)}' == newText;

  static String _leadingWhitespace(String line) {
    final buffer = StringBuffer();
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ' || ch == '\t') {
        buffer.write(ch);
      } else {
        break;
      }
    }
    return buffer.toString();
  }
}
