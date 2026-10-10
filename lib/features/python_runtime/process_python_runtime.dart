import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:skillbridge_python_lab/core/errors/app_exception.dart';
import 'execution_result.dart';
import 'python_runtime.dart';

/// Executes Python by spawning a short-lived host CPython child process that
/// runs `python_app/harness_cli.py`.
///
/// Why this exists:
///  * It gives **real** Python execution on any developer machine (and in
///    automated tests) without a device or emulator, using the exact same
///    `skillbridge_exec.py` that ships inside the mobile app.
///  * The child process can be killed on timeout, giving a genuine hard stop
///    for runaway programs during development.
///
/// It is *not* used to execute learner code on the LMS server, and it is not a
/// security sandbox: it runs under the developer's own account.
class ProcessPythonRuntime implements PythonRuntime {
  ProcessPythonRuntime({
    required this.pythonExecutable,
    String? harnessPath,
    this.defaultTimeout = const Duration(seconds: 10),
    this.defaultMaxOutputChars = 200000,
  }) : harnessPath = harnessPath ?? resolveHarnessPath();

  final String pythonExecutable;
  final String harnessPath;
  final Duration defaultTimeout;
  final int defaultMaxOutputChars;

  Process? _current;
  bool _ready = false;

  /// Set by [cancel] so an in-flight execution resolves to
  /// [ExecutionResult.cancelled] rather than looking like a harness crash.
  bool _cancelRequested = false;

  @override
  String get displayName => 'Host CPython ($pythonExecutable)';

  @override
  bool get isReady => _ready;

  @override
  Future<void> prepare() async {
    final file = File(harnessPath);
    if (!file.existsSync()) {
      _ready = false;
      throw RuntimeException(
        'Python harness not found at $harnessPath. '
        'Ensure python_app/harness_cli.py exists.',
      );
    }
    // Verify the interpreter is reachable and record its version.
    try {
      final probe = await Process.run(pythonExecutable, ['--version']);
      if (probe.exitCode != 0) {
        _ready = false;
        throw RuntimeException('Could not start "$pythonExecutable".');
      }
      _ready = true;
    } on ProcessException catch (e) {
      _ready = false;
      throw RuntimeException(
        'Python interpreter "$pythonExecutable" was not found. '
        'Install Python 3 or set SB_PYTHON_EXECUTABLE.',
        cause: e,
      );
    }
  }

  @override
  Future<ExecutionResult> execute(ExecutionRequest request) async {
    if (!_ready) {
      await prepare();
    }

    final timeout = request.timeout ?? defaultTimeout;
    final maxChars = request.maxOutputChars ?? defaultMaxOutputChars;
    _cancelRequested = false;

    final tempDir = await Directory.systemTemp.createTemp('sb_pyrun_');
    final jobFile = File(p.join(tempDir.path, 'job.json'));
    await jobFile.writeAsString(jsonEncode({
      'code': request.code,
      'stdin': request.stdinLines,
      'maxOutputChars': maxChars,
    }));

    final sw = Stopwatch()..start();
    try {
      final process = await Process.start(
        pythonExecutable,
        [harnessPath, jobFile.path],
      );
      _current = process;

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          timedOut = true;
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      sw.stop();

      final stdout = await stdoutFuture;
      final stderr = await stderrFuture;
      _current = null;

      if (timedOut) {
        return ExecutionResult.timedOut(timeout);
      }
      if (_cancelRequested) {
        return ExecutionResult.cancelled();
      }

      final parsed = _parseResult(stdout);
      if (parsed != null) {
        // Prefer the interpreter-measured duration; fall back to wall clock.
        return parsed;
      }

      // The harness never produced a result: surface the raw error.
      return ExecutionResult(
        status: ExecutionStatus.error,
        stderr: stderr.isNotEmpty ? stderr : 'The Python runtime produced no result.',
        exception: ExecutionException(
          type: 'RuntimeError',
          message: stderr.isNotEmpty ? stderr.trim() : 'No result from runtime (exit $exitCode).',
        ),
        durationMs: sw.elapsedMilliseconds,
      );
    } on ProcessException catch (e) {
      return ExecutionResult.runtimeFailure(
        'Could not start Python: ${e.message}',
      );
    } finally {
      _current = null;
      // Best-effort cleanup; never throw from a finally block.
      try {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> cancel() async {
    _cancelRequested = true;
    final process = _current;
    if (process != null) {
      process.kill(ProcessSignal.sigkill);
      _current = null;
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
    _ready = false;
  }

  /// Extracts the JSON payload printed between the runtime's sentinel markers.
  static ExecutionResult? _parseResult(String stdout) {
    const start = '===SKILLBRIDGE_RESULT_START===';
    const end = '===SKILLBRIDGE_RESULT_END===';
    final startIndex = stdout.indexOf(start);
    final endIndex = stdout.indexOf(end);
    if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
      return null;
    }
    final jsonText = stdout.substring(startIndex + start.length, endIndex).trim();
    try {
      final map = jsonDecode(jsonText) as Map<String, dynamic>;
      return ExecutionResult.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Finds `python_app/harness_cli.py` by walking up from the current directory.
  ///
  /// This keeps the runtime working regardless of whether it is launched from
  /// the project root, a test runner, or a built desktop executable.
  static String resolveHarnessPath() {
    var dir = Directory.current;
    for (var i = 0; i < 8; i++) {
      final candidate = File(p.join(dir.path, 'python_app', 'harness_cli.py'));
      if (candidate.existsSync()) return candidate.path;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    // Fall back to the conventional location.
    return p.join(Directory.current.path, 'python_app', 'harness_cli.py');
  }
}
