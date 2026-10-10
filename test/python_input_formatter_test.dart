import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_python_lab/features/editor/widgets/python_input_formatter.dart';

/// Mirrors what the editing pipeline hands the formatter: the value before the
/// keystroke and the value after the raw text change.
TextEditingValue _collapsed(String text, int offset) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );

void main() {
  late PythonInputFormatter formatter;

  setUp(() => formatter = PythonInputFormatter(indentUnit: '    '));

  /// Types [typed] at [cursor] inside [before] and runs the formatter.
  TextEditingValue typeAt(String before, int cursor, String typed) {
    final old = _collapsed(before, cursor);
    final after = before.replaceRange(cursor, cursor, typed);
    final fresh = _collapsed(after, cursor + typed.length);
    return formatter.formatEditUpdate(old, fresh);
  }

  /// Types [opener] while [before] has [start, end] selected.
  TextEditingValue typeWithSelection(
      String before, int start, int end, String opener) {
    final old = TextEditingValue(
      text: before,
      selection: TextSelection(baseOffset: start, extentOffset: end),
    );
    final after = before.replaceRange(start, end, opener);
    final fresh = _collapsed(after, start + opener.length);
    return formatter.formatEditUpdate(old, fresh);
  }

  group('auto-close', () {
    test('typing ( inserts the matching )', () {
      final result = typeAt('', 0, '(');
      expect(result.text, '()');
      expect(result.selection.extentOffset, 1);
    });

    test('typing [ inserts the matching ]', () {
      final result = typeAt('', 0, '[');
      expect(result.text, '[]');
      expect(result.selection.extentOffset, 1);
    });

    test('typing { inserts the matching }', () {
      final result = typeAt('let x = ', 8, '{');
      expect(result.text, 'let x = {}');
      expect(result.selection.extentOffset, 9);
    });

    test('typing " inserts a closing quote', () {
      final result = typeAt('', 0, '"');
      expect(result.text, '""');
      expect(result.selection.extentOffset, 1);
    });

    test("typing ' inserts a closing quote", () {
      final result = typeAt('name = ', 7, "'");
      expect(result.text, "name = ''");
      expect(result.selection.extentOffset, 8);
    });

    test('auto-closes inside existing code', () {
      // The buffer already holds `print()` with the caret between the parens.
      final result = typeAt('print()', 6, '"');
      expect(result.text, 'print("")');
      expect(result.selection.extentOffset, 7);
    });

    test('closes the quote when there is no matching bracket after it', () {
      final result = typeAt('print(', 6, '"');
      expect(result.text, 'print(""');
      expect(result.selection.extentOffset, 7);
    });
  });

  group('skip over an existing quote', () {
    test('a second " steps over the auto-inserted one instead of doubling it',
        () {
      // After auto-close the buffer holds `""` with the caret between them.
      final result = typeAt('name = ""', 8, '"');
      expect(result.text, 'name = ""');
      expect(result.selection.extentOffset, 9);
    });

    test("works for single quotes", () {
      final result = typeAt("s = ''", 5, "'");
      expect(result.text, "s = ''");
      expect(result.selection.extentOffset, 6);
    });

    test('still auto-closes when the caret is not before a quote', () {
      final result = typeAt('s = ', 4, "'");
      expect(result.text, "s = ''");
      expect(result.selection.extentOffset, 5);
    });
  });

  group('wrap selection', () {
    test('typing ( around a selection wraps it', () {
      final result = typeWithSelection('abc', 1, 2, '(');
      expect(result.text, 'a(b)c');
      expect(result.selection.extentOffset, 3);
    });

    test('typing " around a selection wraps it', () {
      final result = typeWithSelection('name = abc', 7, 10, '"');
      expect(result.text, 'name = "abc"');
      expect(result.selection.extentOffset, 11);
    });

    test('typing [ around a selection wraps it', () {
      final result = typeWithSelection('a = 1, 2, 3', 4, 11, '[');
      expect(result.text, 'a = [1, 2, 3]');
      expect(result.selection.extentOffset, 12);
    });
  });

  group('auto-indent', () {
    test('adds one level after a line ending in :', () {
      final result = typeAt('if a:', 5, '\n');
      expect(result.text, 'if a:\n    ');
      expect(result.selection.extentOffset, 10);
    });

    test('uses the configured indent width', () {
      formatter = PythonInputFormatter(indentUnit: '  ');
      final result = typeAt('def f():', 8, '\n');
      expect(result.text, 'def f():\n  ');
      expect(result.selection.extentOffset, 11);
    });

    test('preserves existing indentation on a plain line', () {
      final result = typeAt('    x = 1', 9, '\n');
      expect(result.text, '    x = 1\n    ');
      expect(result.selection.extentOffset, 14);
    });

    test('keeps the deeper indent of a nested block', () {
      final result = typeAt('    if a:', 9, '\n');
      expect(result.text, '    if a:\n        ');
      expect(result.selection.extentOffset, 18);
    });

    test('adds no indentation to an empty line', () {
      final result = typeAt('', 0, '\n');
      expect(result.text, '\n');
      expect(result.selection.extentOffset, 1);
    });

    test('adds no indentation at the very start of the buffer', () {
      final result = typeAt('abc', 0, '\n');
      expect(result.text, '\nabc');
      expect(result.selection.extentOffset, 1);
    });
  });

  group('passthrough', () {
    test('ordinary characters are returned unchanged', () {
      final result = typeAt('x = ', 4, '1');
      expect(result.text, 'x = 1');
      expect(result.selection.extentOffset, 5);
    });

    test('a closing bracket is not auto-closed', () {
      final result = typeAt('f(', 2, ')');
      expect(result.text, 'f()');
    });

    test('multi-character input is returned unchanged', () {
      final old = _collapsed('x = ', 4);
      final fresh = _collapsed('x = 1 + 2', 9);
      final result = formatter.formatEditUpdate(old, fresh);
      expect(result, fresh);
    });
  });
}
