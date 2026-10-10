import 'execution_result.dart';

/// Request to execute a piece of Python source.
class ExecutionRequest {
  const ExecutionRequest({
    required this.code,
    this.stdinLines = const [],
    this.timeout,
    this.maxOutputChars,
  });

  final String code;

  /// Lines fed to ``input()`` in order. Prevents the program from blocking.
  final List<String> stdinLines;

  final Duration? timeout;
  final int? maxOutputChars;
}

/// Abstract Python execution backend.
///
/// Implementations must:
///  * Never block the UI thread indefinitely.
///  * Never let learner code hang forever (enforce [ExecutionRequest.timeout]).
///  * Truncate runaway output to [ExecutionRequest.maxOutputChars].
///  * Capture stdout, stderr, exceptions and status into an [ExecutionResult].
///
/// **Security note:** this abstraction gives *practical* guard rails, not a
/// hardened sandbox. See `docs/SECURITY_AND_PRIVACY.md`.
abstract class PythonRuntime {
  /// Human readable name of the backend, shown in Settings/diagnostics.
  String get displayName;

  /// True once [prepare] succeeded and the backend can run code.
  bool get isReady;

  /// Prepares the runtime (start embedded server, verify interpreter, ...).
  Future<void> prepare();

  /// Executes [request] and returns a structured result.
  Future<ExecutionResult> execute(ExecutionRequest request);

  /// Requests cancellation of the currently running execution, if any.
  Future<void> cancel();

  /// Releases resources.
  Future<void> dispose();
}
