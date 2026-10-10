import 'package:flutter/material.dart';

import 'package:skillbridge_python_lab/features/python_runtime/execution_result.dart';

/// Displays program output and errors in a terminal-like panel with a clear
/// status line, suited to beginners.
class OutputConsole extends StatelessWidget {
  const OutputConsole({
    super.key,
    required this.result,
    this.isRunning = false,
  });

  final ExecutionResult? result;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBar(result: result, isRunning: isRunning),
          const Divider(height: 1, color: Color(0xFF22304A)),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (isRunning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(height: 10),
            Text('Running…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    final current = result;
    if (current == null) {
      return const Center(
        child: Text(
          'Tap Run to see the output here.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    final buffer = StringBuffer();
    if (current.stdout.isNotEmpty) buffer.write(current.stdout);
    if (current.stderr.isNotEmpty) buffer.write(current.stderr);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (buffer.isEmpty && !current.hasException)
            const Text('(no output)', style: TextStyle(color: Colors.white38)),
          if (buffer.isNotEmpty)
            SelectableText(
              buffer.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(0xFFE6EAF0)),
            ),
          if (current.stdoutTruncated || current.stderrTruncated)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Output was shortened because it was very long.',
                style: TextStyle(color: Color(0xFFF5A623), fontSize: 12),
              ),
            ),
          if (current.exception != null) _ErrorBlock(exception: current.exception!),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.result, required this.isRunning});

  final ExecutionResult? result;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _status();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          if (result != null && result!.durationMs > 0)
            Text('${result!.durationMs} ms',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          if (result != null && result!.pythonVersion.isNotEmpty) ...[
            const SizedBox(width: 10),
            Text('Python ${result!.pythonVersion}',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  (String, Color, IconData) _status() {
    if (isRunning) return ('Running', Colors.white70, Icons.play_arrow);
    final current = result;
    if (current == null) return ('Ready', Colors.white54, Icons.circle_outlined);
    switch (current.status) {
      case ExecutionStatus.success:
        return ('Finished successfully', const Color(0xFF98C379), Icons.check_circle_outline);
      case ExecutionStatus.error:
        return ('Stopped with an error', const Color(0xFFE06C75), Icons.error_outline);
      case ExecutionStatus.timeout:
        return ('Timed out', const Color(0xFFF5A623), Icons.timer_off_outlined);
      case ExecutionStatus.cancelled:
        return ('Stopped', Colors.white54, Icons.stop_circle_outlined);
    }
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.exception});

  final ExecutionException exception;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1D22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF7A3038)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFF5A623), size: 18),
              const SizedBox(width: 6),
              Text(
                exception.friendlyLabel,
                style: const TextStyle(color: Color(0xFFFFD9A0), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${exception.type}: ${exception.message}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFE6EAF0)),
          ),
          if (exception.traceback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Details', style: TextStyle(color: Colors.white70, fontSize: 12)),
                children: [
                  SelectableText(
                    exception.traceback,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 11, color: Color(0xFFB9C2CF)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
