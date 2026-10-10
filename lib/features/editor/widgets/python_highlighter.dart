/// Lightweight, dependency-free Python tokenizer used to colour the code
/// editor. It is intentionally forgiving: it always consumes the entire input,
/// so highlighted spans concatenate back to the exact source text. That
/// invariant is verified in `test/python_highlighter_test.dart`.
library;

enum CodeTokenType {
  keyword,
  builtin,
  string,
  number,
  comment,
  operator,
  identifier,
  plain,
}

class CodeToken {
  const CodeToken(this.text, this.type);
  final String text;
  final CodeTokenType type;
}

class PythonSyntaxHighlighter {
  const PythonSyntaxHighlighter();

  static const Set<String> keywords = {
    'False', 'None', 'True', 'and', 'as', 'assert', 'async', 'await', 'break',
    'class', 'continue', 'def', 'del', 'elif', 'else', 'except', 'finally',
    'for', 'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'nonlocal',
    'not', 'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
    'match', 'case',
  };

  static const Set<String> builtins = {
    'print', 'input', 'len', 'range', 'int', 'float', 'str', 'bool', 'list',
    'dict', 'set', 'tuple', 'sum', 'min', 'max', 'abs', 'round', 'sorted',
    'enumerate', 'zip', 'map', 'filter', 'type', 'isinstance', 'open',
    'append', 'keys', 'values', 'items',
  };

  /// Symbolic operators that may be longer than one character (`==`, `!=`,
  /// `**`, `->`, `+=`, ...). These are consumed as a single token.
  static const String _symbolOperators = '+-*/%=<>!&|^~@';

  /// Single-character punctuation. Kept separate from [_symbolOperators] so
  /// that `f()` tokenises as `(`, `)` rather than one `()` token.
  static const String _punctuation = '.,:()[]{}';

  List<CodeToken> tokenize(String source) {
    final tokens = <CodeToken>[];
    var i = 0;

    void flush(String text, CodeTokenType type) {
      if (text.isNotEmpty) tokens.add(CodeToken(text, type));
    }

    while (i < source.length) {
      final ch = source[i];

      // Comment: # to end of line.
      if (ch == '#') {
        final start = i;
        while (i < source.length && source[i] != '\n') {
          i++;
        }
        flush(source.substring(start, i), CodeTokenType.comment);
        continue;
      }

      // Strings (single, double, and triple-quoted).
      if (ch == '"' || ch == "'") {
        final start = i;
        final triple = i + 2 < source.length &&
            source[i + 1] == ch &&
            source[i + 2] == ch;
        final quote = triple ? ch * 3 : ch;
        i += quote.length;
        while (i < source.length) {
          if (source[i] == r'\' && i + 1 < source.length) {
            i += 2;
            continue;
          }
          if (source.startsWith(quote, i)) {
            i += quote.length;
            break;
          }
          if (!triple && source[i] == '\n') {
            // Unterminated single-line string; stop at the newline so the rest
            // of the line is still highlighted sensibly.
            break;
          }
          i++;
        }
        flush(source.substring(start, i), CodeTokenType.string);
        continue;
      }

      // Numbers (incl. simple floats and underscores).
      if (_isDigit(ch) || (ch == '.' && i + 1 < source.length && _isDigit(source[i + 1]))) {
        final start = i;
        while (i < source.length &&
            (_isDigit(source[i]) || source[i] == '.' || source[i] == '_' ||
                source[i] == 'e' || source[i] == 'E' ||
                ((source[i] == '+' || source[i] == '-') && i > start &&
                    (source[i - 1] == 'e' || source[i - 1] == 'E')))) {
          i++;
        }
        flush(source.substring(start, i), CodeTokenType.number);
        continue;
      }

      // Identifiers, keywords and builtins.
      if (_isIdentStart(ch)) {
        final start = i;
        while (i < source.length && _isIdentPart(source[i])) {
          i++;
        }
        final word = source.substring(start, i);
        final type = keywords.contains(word)
            ? CodeTokenType.keyword
            : (builtins.contains(word) ? CodeTokenType.builtin : CodeTokenType.identifier);
        flush(word, type);
        continue;
      }

      // Whitespace.
      if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        final start = i;
        while (i < source.length &&
            (source[i] == ' ' || source[i] == '\t' || source[i] == '\n' || source[i] == '\r')) {
          i++;
        }
        flush(source.substring(start, i), CodeTokenType.plain);
        continue;
      }

      // Operators and punctuation.
      if (_symbolOperators.contains(ch)) {
        final start = i;
        while (i < source.length && _symbolOperators.contains(source[i])) {
          i++;
        }
        flush(source.substring(start, i), CodeTokenType.operator);
        continue;
      }
      if (_punctuation.contains(ch)) {
        flush(ch, CodeTokenType.operator);
        i++;
        continue;
      }

      // Anything else.
      flush(ch, CodeTokenType.plain);
      i++;
    }

    return tokens;
  }

  static bool _isDigit(String ch) => ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;

  static bool _isIdentStart(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || ch == '_';
  }

  static bool _isIdentPart(String ch) => _isIdentStart(ch) || _isDigit(ch);
}
