/// Structured outcome of executing a piece of Python source.
///
/// This is the contract between the runtime layer and the UI. It is deliberately
/// serialisable so it can be produced by a child process (JSON over stdout), an
/// HTTP call to the embedded runtime, or a mock in tests.
class ExecutionResult {
  const ExecutionResult({
    required this.status,
    this.stdout = '',
    this.stderr = '',
    this.exception,
    this.durationMs = 0,
    this.stdoutTruncated = false,
    this.stderrTruncated = false,
    this.pythonVersion = '',
  });

  final ExecutionStatus status;
  final String stdout;
  final String stderr;
  final ExecutionException? exception;
  final int durationMs;
  final bool stdoutTruncated;
  final bool stderrTruncated;
  final String pythonVersion;

  bool get hasError => status == ExecutionStatus.error;
  bool get isSuccess => status == ExecutionStatus.success;
  bool get isTimeout => status == ExecutionStatus.timeout;
  bool get isCancelled => status == ExecutionStatus.cancelled;

  /// True when there is any learner-visible error information.
  bool get hasException => exception != null;

  /// Combined console text, in the order a terminal would show it.
  String get consoleText {
    final buffer = StringBuffer();
    if (stdout.isNotEmpty) buffer.write(stdout);
    if (stderr.isNotEmpty) buffer.write(stderr);
    return buffer.toString();
  }

  static ExecutionStatus statusFromName(String? name) {
    switch (name) {
      case 'success':
        return ExecutionStatus.success;
      case 'timeout':
        return ExecutionStatus.timeout;
      case 'cancelled':
        return ExecutionStatus.cancelled;
      case 'error':
      default:
        return ExecutionStatus.error;
    }
  }

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    final rawException = json['exception'];
    return ExecutionResult(
      status: statusFromName(json['status'] as String?),
      stdout: (json['stdout'] as String?) ?? '',
      stderr: (json['stderr'] as String?) ?? '',
      exception: rawException is Map<String, dynamic>
          ? ExecutionException.fromJson(rawException)
          : null,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      stdoutTruncated: json['stdoutTruncated'] as bool? ?? false,
      stderrTruncated: json['stderrTruncated'] as bool? ?? false,
      pythonVersion: (json['pythonVersion'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'stdout': stdout,
        'stderr': stderr,
        'exception': exception?.toJson(),
        'durationMs': durationMs,
        'stdoutTruncated': stdoutTruncated,
        'stderrTruncated': stderrTruncated,
        'pythonVersion': pythonVersion,
      };

  /// A result representing infrastructure failure (runtime could not start).
  factory ExecutionResult.runtimeFailure(String message) => ExecutionResult(
        status: ExecutionStatus.error,
        stderr: message,
        exception: ExecutionException(type: 'RuntimeError', message: message),
      );

  factory ExecutionResult.timedOut(Duration timeout) => ExecutionResult(
        status: ExecutionStatus.timeout,
        stderr: 'Your program ran for more than ${timeout.inSeconds} seconds and was stopped. '
            'Check for an infinite loop or a missing condition.',
        exception: const ExecutionException(
          type: 'TimeoutError',
          message: 'Execution timed out',
        ),
      );

  factory ExecutionResult.cancelled() => const ExecutionResult(
        status: ExecutionStatus.cancelled,
        stderr: 'Execution stopped.',
      );
}

enum ExecutionStatus { success, error, timeout, cancelled }

/// Details of a syntax error or runtime exception raised by learner code.
class ExecutionException {
  const ExecutionException({
    required this.type,
    required this.message,
    this.traceback = '',
    this.line,
  });

  final String type;
  final String message;
  final String traceback;

  /// 1-based source line for syntax errors, when known.
  final int? line;

  factory ExecutionException.fromJson(Map<String, dynamic> json) {
    final rawLine = json['line'];
    return ExecutionException(
      type: (json['type'] as String?) ?? 'Error',
      message: (json['message'] as String?) ?? '',
      traceback: (json['traceback'] as String?) ?? '',
      line: rawLine is String ? int.tryParse(rawLine) : rawLine as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'traceback': traceback,
        if (line != null) 'line': line.toString(),
      };

  /// Beginner-friendly one-liner used in the results screen.
  String get friendlyLabel {
    switch (type) {
      case 'SyntaxError':
        return 'There is a spelling or punctuation mistake on line ${line ?? '?'}.';
      case 'NameError':
        return 'You used a variable or name that does not exist yet.';
      case 'TypeError':
        return 'You mixed values of different types (for example, text and a number).';
      case 'IndexError':
        return 'You asked for an item that is outside the list.';
      case 'KeyError':
        return 'The dictionary does not contain that key.';
      case 'ZeroDivisionError':
        return 'You cannot divide by zero.';
      case 'IndentationError':
        return 'The indentation is not correct. Line up blocks of code.';
      case 'EOFError':
        return 'Your program asked for more input than you provided.';
      case 'ValueError':
        return 'A value had the right type but the wrong content.';
      case 'TimeoutError':
        return 'Your program took too long and was stopped.';
      default:
        return message.isEmpty ? 'Something went wrong.' : message;
    }
  }
}
