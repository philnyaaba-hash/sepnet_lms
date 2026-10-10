import 'execution_result.dart';
import 'python_runtime.dart';

/// Deterministic in-process runtime used by widget tests and UI previews where
/// real execution is irrelevant. It never executes code.
class FakePythonRuntime implements PythonRuntime {
  FakePythonRuntime({
    this.result,
    this.onExecute,
  });

  /// Result returned for every execution unless [onExecute] is supplied.
  final ExecutionResult? result;

  /// Optional hook to compute a result per request (useful in tests).
  final ExecutionResult Function(ExecutionRequest request)? onExecute;

  final List<ExecutionRequest> executed = [];
  bool _ready = true;
  bool disposed = false;

  @override
  String get displayName => 'Fake runtime (tests only)';

  @override
  bool get isReady => _ready;

  @override
  Future<void> prepare() async => _ready = true;

  @override
  Future<ExecutionResult> execute(ExecutionRequest request) async {
    executed.add(request);
    if (onExecute != null) return onExecute!(request);
    return result ??
        const ExecutionResult(
          status: ExecutionStatus.success,
          stdout: 'Hello from the fake runtime\n',
          pythonVersion: '3.x (fake)',
        );
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
