import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/app/theme.dart';
import 'code_editing_controller.dart';
import 'python_input_formatter.dart';

/// The code editing surface: a line-number gutter plus a syntax-highlighted,
/// always-editable [TextField].
///
/// Design notes
///  * Native Flutter text field (not a WebView) so selection, IME, copy/paste,
///    accessibility and keyboard insets behave correctly on low-end Android
///    devices. See `docs/CODEMIRROR_EVALUATION.md` for the CodeMirror trade-off.
///  * The gutter and the field share one vertical scroll view so the numbers
///    always line up with the code.
class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    required this.controller,
    required this.fontSize,
    this.focusNode,
    this.onChanged,
    this.indentUnit = '    ',
  });

  final CodeEditingController controller;
  final double fontSize;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String indentUnit;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final PythonInputFormatter _formatter =
      PythonInputFormatter(indentUnit: widget.indentUnit);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  void _onControllerChanged() {
    // Rebuild the gutter when the line count changes.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  double get _lineHeight => widget.fontSize * 1.6;

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(widget.controller.text).length + 1;
    final gutterWidth = (lineCount.toString().length * widget.fontSize * 0.7) + 20;

    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['RobotoMono', 'Courier New', 'Courier'],
      fontSize: widget.fontSize,
      height: 1.6,
      color: AppTheme.tokenVariable,
    );

    return Container(
      color: AppTheme.codeSurface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LineNumberGutter(
              lineCount: lineCount,
              width: gutterWidth,
              lineHeight: _lineHeight,
              fontSize: widget.fontSize,
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                onChanged: widget.onChanged,
                inputFormatters: [_formatter],
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                maxLines: null,
                scrollPadding: const EdgeInsets.only(bottom: 120),
                style: codeStyle,
                cursorColor: AppTheme.brandAmber,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  hintText: '# Write your Python code here',
                  hintStyle: TextStyle(color: Color(0xFF5A6472)),
                ),
                strutStyle: StrutStyle(
                  fontFamily: 'monospace',
                  fontSize: widget.fontSize,
                  height: 1.6,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineNumberGutter extends StatelessWidget {
  const _LineNumberGutter({
    required this.lineCount,
    required this.width,
    required this.lineHeight,
    required this.fontSize,
  });

  final int lineCount;
  final double width;
  final double lineHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.only(right: 8),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF22304A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 1; i <= lineCount; i++)
            SizedBox(
              height: lineHeight,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$i',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: fontSize * 0.85,
                    height: 1.6,
                    color: const Color(0xFF5A6472),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
