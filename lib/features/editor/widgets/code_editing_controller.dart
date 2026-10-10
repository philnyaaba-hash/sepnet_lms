// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/app/theme.dart';
import 'python_highlighter.dart';

/// Colour mapping for Python tokens. Kept separate from the highlighter so the
/// tokenizer stays testable without any Flutter theming.
class CodeEditorPalette {
  const CodeEditorPalette({required this.onCodeSurface});

  final Color onCodeSurface;

  static const CodeEditorPalette dark = CodeEditorPalette(onCodeSurface: Color(0xFFD7DAE0));

  TextStyle? styleFor(CodeTokenType type, TextStyle? base) {
    switch (type) {
      case CodeTokenType.keyword:
        return base?.copyWith(color: AppTheme.tokenKeyword, fontWeight: FontWeight.w600);
      case CodeTokenType.builtin:
        return base?.copyWith(color: AppTheme.tokenBuiltin);
      case CodeTokenType.string:
        return base?.copyWith(color: AppTheme.tokenString);
      case CodeTokenType.number:
        return base?.copyWith(color: AppTheme.tokenNumber);
      case CodeTokenType.comment:
        return base?.copyWith(color: AppTheme.tokenComment, fontStyle: FontStyle.italic);
      case CodeTokenType.operator:
        return base?.copyWith(color: AppTheme.tokenOperator);
      case CodeTokenType.identifier:
        return base?.copyWith(color: onCodeSurface);
      case CodeTokenType.plain:
        return base?.copyWith(color: onCodeSurface);
    }
  }
}

/// A [TextEditingController] that renders Python syntax highlighting by
/// overriding [buildTextSpan]. This keeps selection, cursor and IME behaviour
/// entirely under Flutter's control (unlike a WebView editor), which matters on
/// low-end devices.
class CodeEditingController extends TextEditingController {
  CodeEditingController({
    super.text,
    this.palette = CodeEditorPalette.dark,
    PythonSyntaxHighlighter highlighter = const PythonSyntaxHighlighter(),
  }) : _highlighter = highlighter;

  final CodeEditorPalette palette;
  final PythonSyntaxHighlighter _highlighter;

  /// Exposed for tests.
  List<CodeToken> tokensOf(String source) => _highlighter.tokenize(source);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // A trailing newline terminates the last line; render an explicit span so
    // the caret has something to occupy.
    final source = text;
    final tokens = _highlighter.tokenize(source);

    final children = <TextSpan>[
      for (final token in tokens)
        TextSpan(text: token.text, style: palette.styleFor(token.type, style)),
    ];

    if (source.isEmpty || source.endsWith('\n')) {
      children.add(TextSpan(text: ' ', style: palette.styleFor(CodeTokenType.plain, style)));
    }

    return TextSpan(style: style, children: children);
  }
}
