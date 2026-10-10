import 'package:flutter_test/flutter_test.dart';

import 'package:skillbridge_python_lab/features/editor/widgets/python_highlighter.dart';

void main() {
  const highlighter = PythonSyntaxHighlighter();

  String reassembled(List<CodeToken> tokens) =>
      tokens.map((t) => t.text).join();

  CodeTokenType? typeOf(String source, String needle) {
    for (final token in highlighter.tokenize(source)) {
      if (token.text == needle) return token.type;
    }
    return null;
  }

  group('tokenizer invariants', () {
    const samples = <String>[
      '',
      'print("Hello, World!")',
      'def square(n):\n    return n * n\n',
      '# leading comment\nx = 42  # trailing\n',
      "s = 'single' + \"double\"\n",
      'nums = [1, 2, 3.5, 1_000]\n',
      'if a >= 10 and b != 0:\n    pass\n',
      'x=1\ny=2\n',
      'range(1, 6)',
      'triple = """multi\nline"""\n',
      'unclosed = "no newline',
      'unicode = "text \u{1F40D} \u00FCn\u00EFc\u00F6d\u00E9"\n',
      'weird \u0000\u0001 control chars\n',
      '',
      '   \t\n  \n',
      'a.b.c(d)[e]{f}\n',
      'try:\n    pass\nexcept ValueError as err:\n    raise\n',
      '@decorator\nclass Thing:\n    pass\n',
    ];

    for (final sample in samples) {
      test(
          'tokens concatenate back to the exact source '
          '(${sample.replaceAll('\n', r'\n')})', () {
        final tokens = highlighter.tokenize(sample);
        expect(reassembled(tokens), sample);
        expect(tokens.isEmpty, sample.isEmpty);
        for (final token in tokens) {
          expect(token.text, isNotEmpty);
        }
      });
    }

    test('does not drop or duplicate content on long mixed input', () {
      final buffer = StringBuffer();
      for (var i = 0; i < 200; i++) {
        buffer.writeln('value_$i = 12.5  # note $i');
        buffer.writeln('print("line $i")');
      }
      final source = buffer.toString();
      expect(reassembled(highlighter.tokenize(source)), source);
    });
  });

  group('classification', () {
    test('recognises Python keywords', () {
      expect(typeOf('def foo():', 'def'), CodeTokenType.keyword);
      expect(typeOf('if x else y', 'if'), CodeTokenType.keyword);
      expect(typeOf('return None', 'return'), CodeTokenType.keyword);
      expect(typeOf('True', 'True'), CodeTokenType.keyword);
      expect(typeOf('match subject:', 'match'), CodeTokenType.keyword);
    });

    test('recognises builtins', () {
      expect(typeOf('print(1)', 'print'), CodeTokenType.builtin);
      expect(typeOf('range(5)', 'range'), CodeTokenType.builtin);
      expect(typeOf('len(x)', 'len'), CodeTokenType.builtin);
    });

    test('recognises plain identifiers', () {
      expect(typeOf('total = 1', 'total'), CodeTokenType.identifier);
      expect(typeOf('_private = 1', '_private'), CodeTokenType.identifier);
    });

    test('recognises numbers including floats and underscores', () {
      expect(typeOf('x = 42', '42'), CodeTokenType.number);
      expect(typeOf('x = 3.5', '3.5'), CodeTokenType.number);
      expect(typeOf('x = 1_000', '1_000'), CodeTokenType.number);
      expect(typeOf('x = 1e10', '1e10'), CodeTokenType.number);
      expect(typeOf('x = 1e-3', '1e-3'), CodeTokenType.number);
    });

    test('recognises comments up to end of line only', () {
      expect(typeOf('x = 1  # tail', '# tail'), CodeTokenType.comment);
      expect(typeOf('# whole line', '# whole line'), CodeTokenType.comment);
      // The comment token must not swallow the newline.
      final tokens = highlighter.tokenize('# c\ny = 1\n');
      expect(tokens.first.type, CodeTokenType.comment);
      expect(tokens.first.text.contains('\n'), isFalse);
    });

    test('recognises single, double and triple quoted strings', () {
      expect(typeOf("s = 'a'", "'a'"), CodeTokenType.string);
      expect(typeOf('s = "a"', '"a"'), CodeTokenType.string);
      final triple = highlighter.tokenize('s = """a\nb"""');
      expect(triple.any((t) => t.type == CodeTokenType.string && t.text.contains('\n')),
          isTrue);
    });

    test('keeps an escaped quote inside the string token', () {
      final tokens = highlighter.tokenize(r'''s = "a\"b"''');
      final string = tokens.firstWhere((t) => t.type == CodeTokenType.string);
      expect(string.text, r'"a\"b"');
    });

    test('stops an unterminated string at the newline', () {
      final tokens = highlighter.tokenize('s = "abc\ny = 1\n');
      expect(reassembled(tokens), 's = "abc\ny = 1\n');
      final string = tokens.firstWhere((t) => t.type == CodeTokenType.string);
      expect(string.text, '"abc');
    });

    test('recognises operators and punctuation', () {
      expect(typeOf('a == b', '=='), CodeTokenType.operator);
      expect(typeOf('a + b', '+'), CodeTokenType.operator);
      expect(typeOf('f()', '('), CodeTokenType.operator);
      expect(typeOf('d["k"]', '['), CodeTokenType.operator);
    });
  });
}
